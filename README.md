
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

Steven Traver, Patrick Strutzenberger, Gareth Monger, Rebecca Groom,
Margot Michaud, V. Deepak, James R. Spotila and Ray Chatterji, Javier
Luque, FJDegrange, Christoph Schomburg, Pedro de Siracusa, Zimices,
Kamil S. Jaron, Matt Crook, Ferran Sayol, Mali’o Kodis, photograph by
Melissa Frey, Shyamal, Michael Scroggie, Sarah Werning, Tracy A. Heath,
Emil Schmidt (vectorized by Maxime Dahirel), Scott Hartman, Chris huh,
Gabriela Palomo-Munoz, Peileppe, Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
FunkMonk, Iain Reid, Ben Liebeskind, Dmitry Bogdanov, Andrew A. Farke,
T. Michael Keesey, Falconaumanni and T. Michael Keesey, Sean McCann,
Roberto Díaz Sibaja, M Kolmann, Nobu Tamura, vectorized by Zimices,
Milton Tan, Dean Schnabel, Oscar Sanisidro, Tasman Dixon, Jagged Fang
Designs, Ville-Veikko Sinkkonen, C. Camilo Julián-Caballero, Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization), Emily
Willoughby, Scott Reid, xgirouxb, Joanna Wolfe, Ville Koistinen and T.
Michael Keesey, Hans Hillewaert (vectorized by T. Michael Keesey),
Maxime Dahirel, Darius Nau, Mali’o Kodis, drawing by Manvir Singh, Caleb
M. Brown, Dantheman9758 (vectorized by T. Michael Keesey), Kimberly
Haddrell, Steven Blackwood, Pollyanna von Knorring and T. Michael
Keesey, M. Garfield & K. Anderson (modified by T. Michael Keesey), Nobu
Tamura (vectorized by T. Michael Keesey), Carlos Cano-Barbacil, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Michelle Site, Philip
Chalmers (vectorized by T. Michael Keesey), Mark Witton, Matt Martyniuk
(modified by Serenchia), Yan Wong, Richard J. Harris, Matt Martyniuk, L.
Shyamal, Harold N Eyster, Collin Gross, Jaime Headden, Jessica Anne
Miller, Manabu Bessho-Uehara, Sergio A. Muñoz-Gómez, Brad McFeeters
(vectorized by T. Michael Keesey), Chris Hay, Dann Pigdon, Nobu Tamura,
Richard Parker (vectorized by T. Michael Keesey), Ryan Cupo, Jack Mayer
Wood, Gordon E. Robertson, Servien (vectorized by T. Michael Keesey),
Dein Freund der Baum (vectorized by T. Michael Keesey), Renata F.
Martins, Michael P. Taylor, Mary Harrsch (modified by T. Michael
Keesey), Sharon Wegner-Larsen, Matt Martyniuk (vectorized by T. Michael
Keesey), Becky Barnes, Louis Ranjard, Kailah Thorn & Ben King, Marie
Russell, Beth Reinke, Ernst Haeckel (vectorized by T. Michael Keesey),
Archaeodontosaurus (vectorized by T. Michael Keesey), Raven Amos, David
Liao, Matt Wilkins, E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Tyler Greenfield, Richard
Ruggiero, vectorized by Zimices, Ghedoghedo (vectorized by T. Michael
Keesey), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Katie S.
Collins, Felix Vaux, Aadx, Evan-Amos (vectorized by T. Michael Keesey),
Joseph J. W. Sertich, Mark A. Loewen, Maija Karala, Noah Schlottman,
Griensteidl and T. Michael Keesey, Matthias Buschmann (vectorized by T.
Michael Keesey), Jaime Headden (vectorized by T. Michael Keesey), Inessa
Voet, Pete Buchholz, Mathilde Cordellier, Roule Jammes (vectorized by T.
Michael Keesey), Joedison Rocha, Jerry Oldenettel (vectorized by T.
Michael Keesey), David Orr, Greg Schechter (original photo), Renato
Santos (vector silhouette), Jaime Headden, modified by T. Michael
Keesey, Smokeybjb, Noah Schlottman, photo by Casey Dunn, H. F. O. March
(vectorized by T. Michael Keesey), Bob Goldstein, Vectorization:Jake
Warner, \[unknown\], Juan Carlos Jerí, Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Manabu Sakamoto, Melissa Broussard, T. Michael
Keesey (after Kukalová), Alex Slavenko, Rainer Schoch, Armin Reindl, Kai
R. Caspar, Jesús Gómez, vectorized by Zimices, Birgit Lang, Oren Peles /
vectorized by Yan Wong, Acrocynus (vectorized by T. Michael Keesey),
Andrew A. Farke, modified from original by H. Milne Edwards, Alexandre
Vong, Cagri Cevrim, Walter Vladimir, Didier Descouens (vectorized by T.
Michael Keesey), Jonathan Wells, Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Steven Haddock
• Jellywatch.org, Natasha Vitek, Mo Hassan, Andrew Farke and Joseph
Sertich, DW Bapst (modified from Bulman, 1970), Mike Keesey
(vectorization) and Vaibhavcho (photography), Mercedes Yrayzoz
(vectorized by T. Michael Keesey), Konsta Happonen, from a CC-BY-NC
image by pelhonen on iNaturalist, Tauana J. Cunha, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Blair Perry, CNZdenek, Jakovche,
Robbie N. Cada (modified by T. Michael Keesey), M. A. Broussard, T.
Tischler, Jay Matternes (modified by T. Michael Keesey), Mihai Dragos
(vectorized by T. Michael Keesey), James I. Kirkland, Luis Alcalá, Mark
A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), E. J. Van Nieukerken, A. Laštuvka,
and Z. Laštuvka (vectorized by T. Michael Keesey), Unknown (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Neil Kelley,
Gopal Murali, Noah Schlottman, photo by Gustav Paulay for Moorea
Biocode, Lauren Sumner-Rooney, Matthew E. Clapham, NASA, Ingo Braasch,
Stemonitis (photography) and T. Michael Keesey (vectorization), Michael
B. H. (vectorized by T. Michael Keesey), Anthony Caravaggi, Karl Ragnar
Gjertsen (vectorized by T. Michael Keesey), Robert Gay, Mali’o Kodis,
photograph by Bruno Vellutini, Aviceda (vectorized by T. Michael
Keesey), Todd Marshall, vectorized by Zimices, Bryan Carstens, David
Tana, kotik, Kent Elson Sorgon, Sarah Alewijnse, Francesco Veronesi
(vectorized by T. Michael Keesey), Catherine Yasuda, Konsta Happonen,
from a CC-BY-NC image by sokolkov2002 on iNaturalist, Henry Fairfield
Osborn, vectorized by Zimices, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), David Sim
(photograph) and T. Michael Keesey (vectorization), Lukasiniho, Farelli
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (after Colin M. L. Burnett), Giant Blue
Anteater (vectorized by T. Michael Keesey), B Kimmel, Chloé Schmidt,
Mali’o Kodis, photograph by John Slapcinsky, Christine Axon, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Mali’o Kodis, image by Rebecca Ritger, Noah
Schlottman, photo from Casey Dunn, Jiekun He, Caleb Brown, Steven
Coombs, Espen Horn (model; vectorized by T. Michael Keesey from a photo
by H. Zell), T. Michael Keesey (vectorization); Thorsten Assmann, Jörn
Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea
Matern, Anika Timm, and David W. Wrase (photography), Charles Doolittle
Walcott (vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy,
Matt Martyniuk (modified by T. Michael Keesey), Burton Robert, USFWS,
Jimmy Bernot, Sibi (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Kailah Thorn & Mark Hutchinson, Obsidian Soul
(vectorized by T. Michael Keesey), Tim H. Heupink, Leon Huynen, and
David M. Lambert (vectorized by T. Michael Keesey), A. H. Baldwin
(vectorized by T. Michael Keesey), SauropodomorphMonarch, Darren Naish
(vectorize by T. Michael Keesey), Anilocra (vectorization by Yan Wong),
Robert Bruce Horsfall, vectorized by Zimices, Smokeybjb (vectorized by
T. Michael Keesey), Abraão B. Leite, T. Michael Keesey (after C. De
Muizon), Alexandra van der Geer, Matt Wilkins (photo by Patrick
Kavanagh), T. Michael Keesey (vectorization) and Nadiatalent
(photography), SecretJellyMan - from Mason McNair, J. J. Harrison
(photo) & T. Michael Keesey, Sam Droege (photography) and T. Michael
Keesey (vectorization), Martin Kevil, Darren Naish (vectorized by T.
Michael Keesey), Peter Coxhead, Eric Moody, Mathew Wedel, Ludwik
Gasiorowski, Scarlet23 (vectorized by T. Michael Keesey), T. Michael
Keesey (after Mivart), Henry Lydecker, Yusan Yang, Stacy Spensley
(Modified), Matt Hayes, Smith609 and T. Michael Keesey, Heinrich Harder
(vectorized by T. Michael Keesey), FunkMonk \[Michael B.H.\] (modified
by T. Michael Keesey), Pranav Iyer (grey ideas), Matt Dempsey, Tony
Ayling (vectorized by T. Michael Keesey), Philippe Janvier (vectorized
by T. Michael Keesey), Ellen Edmonson (illustration) and Timothy J.
Bartley (silhouette), Alexander Schmidt-Lebuhn, Alan Manson (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Matthew Hooge (vectorized by T. Michael Keesey), Wynston Cooper (photo)
and Albertonykus (silhouette), MPF (vectorized by T. Michael Keesey),
Stephen O’Connor (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    786.714346 |    197.552303 | Steven Traver                                                                                                                                                                        |
|   2 |    752.324220 |    659.522568 | Patrick Strutzenberger                                                                                                                                                               |
|   3 |    403.754402 |    162.236397 | NA                                                                                                                                                                                   |
|   4 |    153.171596 |    777.026121 | Gareth Monger                                                                                                                                                                        |
|   5 |    774.046013 |    465.389666 | Rebecca Groom                                                                                                                                                                        |
|   6 |    536.930435 |    624.277623 | Margot Michaud                                                                                                                                                                       |
|   7 |    551.131061 |    413.321541 | Steven Traver                                                                                                                                                                        |
|   8 |    160.837519 |    695.329018 | V. Deepak                                                                                                                                                                            |
|   9 |    929.962891 |    623.337693 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
|  10 |     85.397398 |    528.040090 | Javier Luque                                                                                                                                                                         |
|  11 |    890.819262 |    503.848609 | FJDegrange                                                                                                                                                                           |
|  12 |    241.747613 |    519.863119 | Christoph Schomburg                                                                                                                                                                  |
|  13 |    496.502492 |    511.397681 | Pedro de Siracusa                                                                                                                                                                    |
|  14 |    643.697671 |     60.953414 | Zimices                                                                                                                                                                              |
|  15 |    933.824163 |    289.115286 | Kamil S. Jaron                                                                                                                                                                       |
|  16 |    818.291055 |    388.517703 | Matt Crook                                                                                                                                                                           |
|  17 |    522.391368 |    735.585747 | Ferran Sayol                                                                                                                                                                         |
|  18 |    369.548477 |    534.802924 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
|  19 |    878.663949 |    755.227206 | Shyamal                                                                                                                                                                              |
|  20 |    920.529569 |     80.706234 | Michael Scroggie                                                                                                                                                                     |
|  21 |    246.051547 |    317.069949 | Sarah Werning                                                                                                                                                                        |
|  22 |    135.944340 |    165.220738 | Tracy A. Heath                                                                                                                                                                       |
|  23 |    328.032655 |    737.179755 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
|  24 |    648.164815 |    293.055897 | Scott Hartman                                                                                                                                                                        |
|  25 |    693.681094 |    559.333227 | Margot Michaud                                                                                                                                                                       |
|  26 |     90.109308 |    591.580755 | Chris huh                                                                                                                                                                            |
|  27 |    483.924829 |    362.653476 | NA                                                                                                                                                                                   |
|  28 |    102.969109 |     45.752699 | NA                                                                                                                                                                                   |
|  29 |    117.262078 |    222.779613 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  30 |    672.603964 |    226.161438 | NA                                                                                                                                                                                   |
|  31 |    454.519014 |     45.533162 | Gareth Monger                                                                                                                                                                        |
|  32 |    614.524195 |    622.562331 | Peileppe                                                                                                                                                                             |
|  33 |    660.780572 |    755.197454 | Zimices                                                                                                                                                                              |
|  34 |    709.865612 |    366.452246 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                               |
|  35 |    404.869151 |    649.269154 | Scott Hartman                                                                                                                                                                        |
|  36 |    194.972934 |    379.072028 | FunkMonk                                                                                                                                                                             |
|  37 |    432.301345 |    688.653176 | Iain Reid                                                                                                                                                                            |
|  38 |    646.581047 |    477.758090 | Ben Liebeskind                                                                                                                                                                       |
|  39 |     67.251676 |    392.593409 | Zimices                                                                                                                                                                              |
|  40 |    410.844222 |    377.705182 | NA                                                                                                                                                                                   |
|  41 |    970.313507 |    185.909626 | Gareth Monger                                                                                                                                                                        |
|  42 |    939.205893 |    405.675690 | Dmitry Bogdanov                                                                                                                                                                      |
|  43 |    259.461910 |     47.791252 | NA                                                                                                                                                                                   |
|  44 |    413.548442 |    282.848366 | Scott Hartman                                                                                                                                                                        |
|  45 |    629.089451 |    349.487530 | Andrew A. Farke                                                                                                                                                                      |
|  46 |     99.666934 |    309.530174 | T. Michael Keesey                                                                                                                                                                    |
|  47 |     25.864843 |    207.747033 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|  48 |    224.712429 |     85.815766 | T. Michael Keesey                                                                                                                                                                    |
|  49 |    281.708492 |    664.937675 | Andrew A. Farke                                                                                                                                                                      |
|  50 |    414.653904 |    760.710831 | Sean McCann                                                                                                                                                                          |
|  51 |    790.718605 |     71.832431 | Margot Michaud                                                                                                                                                                       |
|  52 |    960.206568 |    495.586699 | Ferran Sayol                                                                                                                                                                         |
|  53 |    767.055301 |    540.966913 | Dmitry Bogdanov                                                                                                                                                                      |
|  54 |    947.685327 |    715.814559 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  55 |     60.887121 |    654.035002 | M Kolmann                                                                                                                                                                            |
|  56 |    952.081595 |     24.192654 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  57 |    764.920446 |    753.302484 | Scott Hartman                                                                                                                                                                        |
|  58 |    550.764382 |    781.317144 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  59 |    318.732140 |    413.992759 | NA                                                                                                                                                                                   |
|  60 |     74.803592 |    746.267438 | Milton Tan                                                                                                                                                                           |
|  61 |     99.716743 |    458.236763 | Dean Schnabel                                                                                                                                                                        |
|  62 |    706.761401 |    396.294941 | Scott Hartman                                                                                                                                                                        |
|  63 |    483.939209 |    290.455257 | Oscar Sanisidro                                                                                                                                                                      |
|  64 |    916.803098 |    686.140669 | Tasman Dixon                                                                                                                                                                         |
|  65 |    770.788816 |    254.958996 | T. Michael Keesey                                                                                                                                                                    |
|  66 |    697.762061 |    158.108679 | Margot Michaud                                                                                                                                                                       |
|  67 |    878.420888 |    351.690527 | Jagged Fang Designs                                                                                                                                                                  |
|  68 |    772.573324 |    749.396071 | Margot Michaud                                                                                                                                                                       |
|  69 |    708.127114 |    324.529719 | Margot Michaud                                                                                                                                                                       |
|  70 |    548.494305 |    543.115503 | Ville-Veikko Sinkkonen                                                                                                                                                               |
|  71 |    379.633660 |    411.527935 | Margot Michaud                                                                                                                                                                       |
|  72 |    486.367175 |    394.472466 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  73 |    833.083131 |    523.627964 | Gareth Monger                                                                                                                                                                        |
|  74 |    998.295633 |    506.066190 | NA                                                                                                                                                                                   |
|  75 |    562.346668 |    305.510771 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  76 |    345.293141 |    296.975325 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                               |
|  77 |    903.106731 |    576.774616 | Emily Willoughby                                                                                                                                                                     |
|  78 |    990.679313 |    367.476944 | Matt Crook                                                                                                                                                                           |
|  79 |    209.510841 |    636.518707 | Jagged Fang Designs                                                                                                                                                                  |
|  80 |    611.107264 |    688.223527 | Scott Reid                                                                                                                                                                           |
|  81 |    416.552401 |    405.574505 | Margot Michaud                                                                                                                                                                       |
|  82 |    333.353721 |    317.687457 | T. Michael Keesey                                                                                                                                                                    |
|  83 |    144.299439 |    394.107002 | Chris huh                                                                                                                                                                            |
|  84 |    839.442233 |    714.803877 | Sarah Werning                                                                                                                                                                        |
|  85 |    542.131411 |    204.568128 | xgirouxb                                                                                                                                                                             |
|  86 |    131.313188 |    491.662705 | Joanna Wolfe                                                                                                                                                                         |
|  87 |    720.974466 |    238.057181 | Rebecca Groom                                                                                                                                                                        |
|  88 |    211.093028 |    243.756768 | Ville Koistinen and T. Michael Keesey                                                                                                                                                |
|  89 |     42.814351 |    783.289773 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
|  90 |    270.274431 |    550.315470 | Scott Hartman                                                                                                                                                                        |
|  91 |    181.303821 |    452.654948 | T. Michael Keesey                                                                                                                                                                    |
|  92 |    576.087945 |     36.276360 | Maxime Dahirel                                                                                                                                                                       |
|  93 |    555.004893 |    456.800624 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
|  94 |     86.736604 |    288.922862 | Zimices                                                                                                                                                                              |
|  95 |    217.086152 |    749.902640 | Darius Nau                                                                                                                                                                           |
|  96 |    826.095132 |    432.239084 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                                |
|  97 |    804.230239 |    746.741941 | Caleb M. Brown                                                                                                                                                                       |
|  98 |   1000.754665 |    213.346974 | NA                                                                                                                                                                                   |
|  99 |    107.186471 |    176.967948 | Gareth Monger                                                                                                                                                                        |
| 100 |    156.099419 |    219.344540 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                      |
| 101 |     27.775628 |    712.873316 | Matt Crook                                                                                                                                                                           |
| 102 |   1007.340043 |    322.715088 | Matt Crook                                                                                                                                                                           |
| 103 |    768.940319 |    171.342838 | Steven Traver                                                                                                                                                                        |
| 104 |    575.880890 |    636.037810 | Dean Schnabel                                                                                                                                                                        |
| 105 |    600.472690 |    315.744886 | Sarah Werning                                                                                                                                                                        |
| 106 |    825.364042 |    454.614410 | Christoph Schomburg                                                                                                                                                                  |
| 107 |    952.998131 |    217.292902 | Kimberly Haddrell                                                                                                                                                                    |
| 108 |    181.014434 |    537.257132 | Christoph Schomburg                                                                                                                                                                  |
| 109 |    754.611084 |     23.202908 | Steven Blackwood                                                                                                                                                                     |
| 110 |     83.223854 |    615.204676 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 111 |    258.579408 |    738.357746 | Matt Crook                                                                                                                                                                           |
| 112 |   1010.844806 |    161.584103 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 113 |    280.760514 |    616.080673 | Scott Reid                                                                                                                                                                           |
| 114 |    584.823565 |    211.647585 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 115 |    875.177010 |     18.359970 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 116 |    114.629882 |    785.085637 | Chris huh                                                                                                                                                                            |
| 117 |    614.963218 |    549.291031 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 118 |   1005.473112 |    693.340472 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 119 |     12.192776 |    315.240834 | NA                                                                                                                                                                                   |
| 120 |    799.503125 |    790.936790 | Michelle Site                                                                                                                                                                        |
| 121 |     65.440558 |    258.946307 | Dean Schnabel                                                                                                                                                                        |
| 122 |    175.210353 |    748.302525 | Zimices                                                                                                                                                                              |
| 123 |    739.258918 |    287.492196 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 124 |    552.709690 |    362.858125 | Mark Witton                                                                                                                                                                          |
| 125 |    871.521849 |    658.199371 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 126 |    449.862702 |    615.613177 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 127 |     34.166917 |    118.986952 | Matt Crook                                                                                                                                                                           |
| 128 |     97.251039 |    633.684432 | Yan Wong                                                                                                                                                                             |
| 129 |    725.178586 |    406.355655 | Matt Crook                                                                                                                                                                           |
| 130 |    586.942651 |    254.540791 | Richard J. Harris                                                                                                                                                                    |
| 131 |    656.761089 |    321.997092 | Matt Martyniuk                                                                                                                                                                       |
| 132 |    448.856837 |    626.375068 | Jagged Fang Designs                                                                                                                                                                  |
| 133 |    292.139589 |    784.396489 | Dean Schnabel                                                                                                                                                                        |
| 134 |    159.368376 |    568.080458 | L. Shyamal                                                                                                                                                                           |
| 135 |    564.758664 |    690.945476 | Tasman Dixon                                                                                                                                                                         |
| 136 |    494.988401 |    705.514207 | M Kolmann                                                                                                                                                                            |
| 137 |    312.002727 |    245.365932 | Harold N Eyster                                                                                                                                                                      |
| 138 |    631.817843 |    150.031035 | Collin Gross                                                                                                                                                                         |
| 139 |    366.054283 |    718.729226 | Jaime Headden                                                                                                                                                                        |
| 140 |    872.090709 |    640.561107 | Jessica Anne Miller                                                                                                                                                                  |
| 141 |    543.610632 |     53.765886 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 142 |    625.881085 |    712.054692 | Jagged Fang Designs                                                                                                                                                                  |
| 143 |    465.619675 |    587.609269 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 144 |    885.938613 |    432.925489 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 145 |     65.199914 |    719.953986 | NA                                                                                                                                                                                   |
| 146 |    624.146615 |    407.262480 | Chris Hay                                                                                                                                                                            |
| 147 |    788.416765 |    536.711173 | Steven Traver                                                                                                                                                                        |
| 148 |    940.231024 |    466.708172 | Dean Schnabel                                                                                                                                                                        |
| 149 |    863.865948 |    601.492185 | Dann Pigdon                                                                                                                                                                          |
| 150 |    386.849903 |    422.359587 | Nobu Tamura                                                                                                                                                                          |
| 151 |    218.183945 |    792.479755 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                     |
| 152 |    986.299932 |    708.728067 | Chris huh                                                                                                                                                                            |
| 153 |    207.607666 |    595.861480 | NA                                                                                                                                                                                   |
| 154 |    953.530956 |    340.733069 | Ryan Cupo                                                                                                                                                                            |
| 155 |    993.041819 |     32.003738 | Jack Mayer Wood                                                                                                                                                                      |
| 156 |    279.609455 |    294.118530 | Gordon E. Robertson                                                                                                                                                                  |
| 157 |    862.509092 |    434.424341 | Servien (vectorized by T. Michael Keesey)                                                                                                                                            |
| 158 |    623.991342 |    128.370190 | Scott Hartman                                                                                                                                                                        |
| 159 |     61.676354 |    160.013223 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                               |
| 160 |    576.197213 |    616.021916 | Chris huh                                                                                                                                                                            |
| 161 |     44.364176 |    403.872109 | Caleb M. Brown                                                                                                                                                                       |
| 162 |    203.261267 |    607.231330 | Gareth Monger                                                                                                                                                                        |
| 163 |    142.148774 |    641.004147 | Jaime Headden                                                                                                                                                                        |
| 164 |   1013.904460 |    522.006132 | Matt Crook                                                                                                                                                                           |
| 165 |    672.703877 |    796.301093 | Dmitry Bogdanov                                                                                                                                                                      |
| 166 |    452.901773 |    572.594899 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 167 |     69.914839 |    702.260689 | Renata F. Martins                                                                                                                                                                    |
| 168 |    597.310906 |    374.424975 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 169 |    275.067596 |    709.794681 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 170 |    646.302952 |    116.199323 | Michael P. Taylor                                                                                                                                                                    |
| 171 |    143.775091 |    321.679643 | Chris huh                                                                                                                                                                            |
| 172 |    851.207817 |    422.301354 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 173 |    886.504871 |    302.025843 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 174 |    696.371437 |    415.282456 | Matt Crook                                                                                                                                                                           |
| 175 |    444.545884 |    550.369178 | Matt Crook                                                                                                                                                                           |
| 176 |    139.918522 |    265.830648 | Gareth Monger                                                                                                                                                                        |
| 177 |    745.461413 |    194.873621 | Steven Traver                                                                                                                                                                        |
| 178 |    795.729955 |    720.582249 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 179 |    839.153442 |    209.562179 | Becky Barnes                                                                                                                                                                         |
| 180 |    994.689913 |     78.735576 | Zimices                                                                                                                                                                              |
| 181 |    143.461599 |     76.015792 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 182 |    522.017901 |    328.096593 | Chris huh                                                                                                                                                                            |
| 183 |    733.104789 |     83.414007 | Louis Ranjard                                                                                                                                                                        |
| 184 |    402.589922 |    436.755969 | NA                                                                                                                                                                                   |
| 185 |    606.550690 |     22.993488 | Caleb M. Brown                                                                                                                                                                       |
| 186 |    144.259762 |    117.616773 | Gareth Monger                                                                                                                                                                        |
| 187 |    412.778716 |     10.466846 | Jagged Fang Designs                                                                                                                                                                  |
| 188 |     62.370522 |    422.298391 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 189 |    824.838936 |    352.054018 | Margot Michaud                                                                                                                                                                       |
| 190 |    125.395807 |    722.787646 | NA                                                                                                                                                                                   |
| 191 |    660.849170 |     14.086437 | Kailah Thorn & Ben King                                                                                                                                                              |
| 192 |    373.195303 |    757.672994 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 193 |    574.916762 |     65.983851 | Steven Traver                                                                                                                                                                        |
| 194 |    402.728589 |    696.721396 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 195 |    147.901236 |    574.140937 | Marie Russell                                                                                                                                                                        |
| 196 |    523.952619 |    439.178905 | Beth Reinke                                                                                                                                                                          |
| 197 |    800.542171 |    586.479077 | Margot Michaud                                                                                                                                                                       |
| 198 |    987.609383 |    298.091797 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 199 |    577.963240 |    290.372382 | Michelle Site                                                                                                                                                                        |
| 200 |    879.518472 |    130.315492 | Beth Reinke                                                                                                                                                                          |
| 201 |    593.760367 |    195.602968 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 202 |    504.288728 |    682.697397 | Sarah Werning                                                                                                                                                                        |
| 203 |    616.056160 |    726.783251 | Sarah Werning                                                                                                                                                                        |
| 204 |    356.251318 |     40.383221 | Beth Reinke                                                                                                                                                                          |
| 205 |    569.611870 |    729.986175 | Raven Amos                                                                                                                                                                           |
| 206 |    750.031868 |    419.466671 | Matt Crook                                                                                                                                                                           |
| 207 |    936.870819 |    533.677483 | David Liao                                                                                                                                                                           |
| 208 |    984.623132 |    665.039215 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 209 |    998.690848 |    115.806205 | Matt Wilkins                                                                                                                                                                         |
| 210 |    652.609963 |    305.174685 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 211 |    997.275348 |    653.114360 | NA                                                                                                                                                                                   |
| 212 |    247.250709 |     95.263751 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 213 |    680.191724 |    141.585987 | Zimices                                                                                                                                                                              |
| 214 |     29.011972 |    686.449691 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 215 |    703.186153 |     30.498497 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 216 |    487.317693 |    232.730870 | Collin Gross                                                                                                                                                                         |
| 217 |    255.375325 |     14.948850 | Tyler Greenfield                                                                                                                                                                     |
| 218 |    917.163731 |    222.208423 | Emily Willoughby                                                                                                                                                                     |
| 219 |    920.872755 |    437.881312 | Richard Ruggiero, vectorized by Zimices                                                                                                                                              |
| 220 |    918.009665 |    665.387530 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 221 |    757.286187 |    630.403101 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 222 |   1014.674304 |    633.543097 | T. Michael Keesey                                                                                                                                                                    |
| 223 |   1008.059718 |    560.247122 | Zimices                                                                                                                                                                              |
| 224 |    456.309589 |    423.129947 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                       |
| 225 |    892.971283 |    322.138146 | Katie S. Collins                                                                                                                                                                     |
| 226 |    982.980214 |    323.794470 | Jagged Fang Designs                                                                                                                                                                  |
| 227 |     83.498524 |    339.448984 | Felix Vaux                                                                                                                                                                           |
| 228 |    217.596981 |    733.859542 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 229 |    359.517659 |    322.621946 | Jaime Headden                                                                                                                                                                        |
| 230 |    887.539463 |    695.896443 | FunkMonk                                                                                                                                                                             |
| 231 |    348.974919 |    436.459712 | Sarah Werning                                                                                                                                                                        |
| 232 |     11.072834 |    285.293298 | Aadx                                                                                                                                                                                 |
| 233 |    905.180061 |    151.125213 | T. Michael Keesey                                                                                                                                                                    |
| 234 |    852.729173 |    588.859656 | NA                                                                                                                                                                                   |
| 235 |    646.490368 |    419.493738 | Gareth Monger                                                                                                                                                                        |
| 236 |    263.687535 |    243.394237 | Gareth Monger                                                                                                                                                                        |
| 237 |    724.637073 |    259.707134 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 238 |    606.042111 |    239.328174 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
| 239 |    928.600331 |    782.361679 | Matt Crook                                                                                                                                                                           |
| 240 |    268.038007 |     88.444004 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 241 |    231.140022 |    593.484691 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
| 242 |    853.803510 |    329.923870 | Scott Hartman                                                                                                                                                                        |
| 243 |    202.637579 |    767.131857 | Dean Schnabel                                                                                                                                                                        |
| 244 |    558.314147 |    274.532483 | Kamil S. Jaron                                                                                                                                                                       |
| 245 |     35.050151 |     33.188934 | Jaime Headden                                                                                                                                                                        |
| 246 |    370.411346 |    355.367413 | Matt Crook                                                                                                                                                                           |
| 247 |     50.609191 |    338.964441 | Matt Crook                                                                                                                                                                           |
| 248 |    503.001475 |    631.823468 | Chris huh                                                                                                                                                                            |
| 249 |    302.803717 |    237.395909 | Jagged Fang Designs                                                                                                                                                                  |
| 250 |    431.817026 |    607.282437 | Maija Karala                                                                                                                                                                         |
| 251 |   1005.729833 |    287.314746 | Ferran Sayol                                                                                                                                                                         |
| 252 |    996.237076 |    609.615387 | Ferran Sayol                                                                                                                                                                         |
| 253 |    504.688839 |    619.939432 | Noah Schlottman                                                                                                                                                                      |
| 254 |    256.951397 |    413.816125 | Chris huh                                                                                                                                                                            |
| 255 |     34.544525 |    453.277887 | Zimices                                                                                                                                                                              |
| 256 |    940.328579 |    551.309521 | Steven Traver                                                                                                                                                                        |
| 257 |    969.707986 |    302.509436 | M Kolmann                                                                                                                                                                            |
| 258 |    705.209408 |      7.889435 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 259 |     43.403173 |     92.702131 | Zimices                                                                                                                                                                              |
| 260 |    168.452329 |    294.215060 | T. Michael Keesey                                                                                                                                                                    |
| 261 |     26.005465 |    311.939984 | Matt Crook                                                                                                                                                                           |
| 262 |    230.211004 |      9.881742 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                                 |
| 263 |    593.543299 |    384.786444 | NA                                                                                                                                                                                   |
| 264 |    757.058565 |    621.286516 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 265 |     41.734591 |    677.117161 | Inessa Voet                                                                                                                                                                          |
| 266 |     65.246914 |    108.242594 | Pete Buchholz                                                                                                                                                                        |
| 267 |    227.884124 |    410.601598 | T. Michael Keesey                                                                                                                                                                    |
| 268 |    288.060070 |    319.709070 | Mathilde Cordellier                                                                                                                                                                  |
| 269 |     98.057698 |    333.976289 | Jagged Fang Designs                                                                                                                                                                  |
| 270 |    289.967938 |    346.061816 | Tasman Dixon                                                                                                                                                                         |
| 271 |    290.793870 |    260.729522 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                       |
| 272 |     24.317752 |    419.923811 | Katie S. Collins                                                                                                                                                                     |
| 273 |    443.553494 |    251.246709 | Margot Michaud                                                                                                                                                                       |
| 274 |    828.363744 |    770.469266 | xgirouxb                                                                                                                                                                             |
| 275 |    150.364381 |     88.866592 | Zimices                                                                                                                                                                              |
| 276 |    179.337115 |    405.501035 | Michael Scroggie                                                                                                                                                                     |
| 277 |    181.523790 |    494.147302 | FunkMonk                                                                                                                                                                             |
| 278 |    750.744580 |    340.877478 | Joedison Rocha                                                                                                                                                                       |
| 279 |    624.374939 |    236.061043 | Matt Crook                                                                                                                                                                           |
| 280 |    198.121669 |    567.954845 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 281 |   1016.270561 |    192.851700 | David Orr                                                                                                                                                                            |
| 282 |    630.371723 |    446.605092 | Matt Crook                                                                                                                                                                           |
| 283 |    629.931285 |    302.293782 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 284 |    784.840002 |     39.055945 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 285 |    379.536188 |    669.864716 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 286 |    186.911841 |    329.610119 | Smokeybjb                                                                                                                                                                            |
| 287 |    755.102611 |    740.715882 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 288 |    598.715920 |    271.160115 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 289 |      8.937670 |     35.529723 | Matt Crook                                                                                                                                                                           |
| 290 |    541.822002 |     70.394449 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                                             |
| 291 |    420.202079 |    691.453185 | Shyamal                                                                                                                                                                              |
| 292 |     44.397959 |    430.436661 | Scott Hartman                                                                                                                                                                        |
| 293 |    992.444399 |     64.736552 | Matt Crook                                                                                                                                                                           |
| 294 |    709.671134 |     74.382330 | Margot Michaud                                                                                                                                                                       |
| 295 |    210.713763 |    124.344895 | \[unknown\]                                                                                                                                                                          |
| 296 |    563.523241 |    247.210882 | Juan Carlos Jerí                                                                                                                                                                     |
| 297 |    997.373905 |    529.228908 | NA                                                                                                                                                                                   |
| 298 |    579.902848 |    388.219503 | Tracy A. Heath                                                                                                                                                                       |
| 299 |    860.956152 |    314.961790 | T. Michael Keesey                                                                                                                                                                    |
| 300 |    484.065687 |    426.671581 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                             |
| 301 |     90.721535 |    719.555821 | Zimices                                                                                                                                                                              |
| 302 |    357.790012 |    690.719141 | Joanna Wolfe                                                                                                                                                                         |
| 303 |    976.795883 |    409.349918 | Chris huh                                                                                                                                                                            |
| 304 |     23.541392 |     50.831225 | Manabu Sakamoto                                                                                                                                                                      |
| 305 |    866.069661 |    125.378228 | Melissa Broussard                                                                                                                                                                    |
| 306 |    804.733311 |    124.899686 | Jaime Headden                                                                                                                                                                        |
| 307 |    956.629372 |    782.174551 | Jaime Headden                                                                                                                                                                        |
| 308 |    847.003766 |    567.742283 | Margot Michaud                                                                                                                                                                       |
| 309 |    279.598906 |     11.376616 | Margot Michaud                                                                                                                                                                       |
| 310 |   1012.395122 |    595.245389 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 311 |     15.930784 |    696.203299 | Alex Slavenko                                                                                                                                                                        |
| 312 |   1006.034548 |    254.989382 | Rainer Schoch                                                                                                                                                                        |
| 313 |    564.981523 |    520.505693 | Margot Michaud                                                                                                                                                                       |
| 314 |     65.675908 |    573.016599 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 315 |    980.311007 |    338.464823 | Mathilde Cordellier                                                                                                                                                                  |
| 316 |    857.987684 |    558.836169 | Armin Reindl                                                                                                                                                                         |
| 317 |    589.581804 |    705.610677 | Margot Michaud                                                                                                                                                                       |
| 318 |    780.505393 |     26.133357 | NA                                                                                                                                                                                   |
| 319 |    910.248326 |    183.338640 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 320 |    635.215994 |    566.196877 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 321 |    292.224595 |    309.544693 | Rebecca Groom                                                                                                                                                                        |
| 322 |    622.341780 |    562.109924 | NA                                                                                                                                                                                   |
| 323 |    853.361589 |    772.102844 | Kai R. Caspar                                                                                                                                                                        |
| 324 |    685.159218 |    263.355655 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 325 |    690.957122 |    501.814323 | Ferran Sayol                                                                                                                                                                         |
| 326 |    328.909559 |     13.199862 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 327 |    651.562056 |     97.419525 | Birgit Lang                                                                                                                                                                          |
| 328 |    719.588493 |    493.732468 | Zimices                                                                                                                                                                              |
| 329 |    442.050989 |    410.904478 | Ferran Sayol                                                                                                                                                                         |
| 330 |    576.910566 |    714.378335 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 331 |    289.474877 |    730.061367 | Matt Crook                                                                                                                                                                           |
| 332 |    792.382376 |    199.178546 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 333 |    108.202746 |    198.076533 | Tasman Dixon                                                                                                                                                                         |
| 334 |    262.478103 |    276.190612 | Dean Schnabel                                                                                                                                                                        |
| 335 |    583.940187 |    539.425198 | Matt Crook                                                                                                                                                                           |
| 336 |    350.899923 |    401.422074 | Tasman Dixon                                                                                                                                                                         |
| 337 |    180.161518 |    470.748862 | Beth Reinke                                                                                                                                                                          |
| 338 |    533.884816 |    321.745220 | Chris huh                                                                                                                                                                            |
| 339 |    959.189372 |    588.338586 | NA                                                                                                                                                                                   |
| 340 |    736.940838 |    247.581439 | Gareth Monger                                                                                                                                                                        |
| 341 |   1014.363347 |    419.506344 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 342 |    808.176973 |     23.206347 | Alexandre Vong                                                                                                                                                                       |
| 343 |    507.620487 |    707.131462 | L. Shyamal                                                                                                                                                                           |
| 344 |    269.999692 |    257.461886 | Jagged Fang Designs                                                                                                                                                                  |
| 345 |    797.859588 |    508.075613 | Ferran Sayol                                                                                                                                                                         |
| 346 |    980.045234 |    141.174084 | Steven Traver                                                                                                                                                                        |
| 347 |    612.657858 |    454.496362 | Ferran Sayol                                                                                                                                                                         |
| 348 |    295.728888 |    210.341383 | Katie S. Collins                                                                                                                                                                     |
| 349 |    527.043312 |    711.607265 | Steven Traver                                                                                                                                                                        |
| 350 |    902.060487 |    277.722051 | Matt Crook                                                                                                                                                                           |
| 351 |    513.237755 |    383.418487 | NA                                                                                                                                                                                   |
| 352 |    127.585016 |     90.475183 | Matt Crook                                                                                                                                                                           |
| 353 |    568.897721 |    480.614623 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 354 |     46.811091 |    588.671926 | Margot Michaud                                                                                                                                                                       |
| 355 |    102.271324 |    118.753215 | Zimices                                                                                                                                                                              |
| 356 |    634.521721 |     24.242055 | Chris huh                                                                                                                                                                            |
| 357 |    797.162594 |    237.743130 | FunkMonk                                                                                                                                                                             |
| 358 |    176.488008 |     22.668591 | NA                                                                                                                                                                                   |
| 359 |    976.122413 |    255.177659 | T. Michael Keesey                                                                                                                                                                    |
| 360 |      8.841374 |    739.569359 | Tracy A. Heath                                                                                                                                                                       |
| 361 |    276.970980 |    533.884757 | xgirouxb                                                                                                                                                                             |
| 362 |    235.217024 |    741.359663 | Margot Michaud                                                                                                                                                                       |
| 363 |    165.816576 |    455.762477 | Ferran Sayol                                                                                                                                                                         |
| 364 |    603.567620 |    174.076770 | Cagri Cevrim                                                                                                                                                                         |
| 365 |    193.599084 |    230.356342 | NA                                                                                                                                                                                   |
| 366 |    115.409139 |    631.809638 | NA                                                                                                                                                                                   |
| 367 |     41.840409 |    622.142748 | Walter Vladimir                                                                                                                                                                      |
| 368 |    409.679843 |    266.037235 | Zimices                                                                                                                                                                              |
| 369 |    158.254878 |    604.105011 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 370 |   1005.344151 |    572.276511 | Jonathan Wells                                                                                                                                                                       |
| 371 |    215.746170 |    375.948784 | NA                                                                                                                                                                                   |
| 372 |    632.120510 |    787.262576 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 373 |    832.449566 |     60.341791 | Melissa Broussard                                                                                                                                                                    |
| 374 |    672.724340 |    779.370269 | Gareth Monger                                                                                                                                                                        |
| 375 |    919.253353 |    113.679898 | NA                                                                                                                                                                                   |
| 376 |    222.890139 |    622.930779 | Margot Michaud                                                                                                                                                                       |
| 377 |    621.209697 |    381.340321 | Margot Michaud                                                                                                                                                                       |
| 378 |    675.663060 |    248.212684 | NA                                                                                                                                                                                   |
| 379 |    383.546545 |    795.722541 | T. Michael Keesey                                                                                                                                                                    |
| 380 |    310.116071 |    274.240737 | Nobu Tamura                                                                                                                                                                          |
| 381 |    980.079040 |    603.122511 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 382 |     84.739046 |    101.734808 | Tyler Greenfield                                                                                                                                                                     |
| 383 |    925.193311 |    148.377329 | Tracy A. Heath                                                                                                                                                                       |
| 384 |    221.710141 |    564.604870 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 385 |    938.348131 |    174.805161 | Ferran Sayol                                                                                                                                                                         |
| 386 |   1007.113253 |    538.685782 | Gareth Monger                                                                                                                                                                        |
| 387 |    815.385075 |     52.611766 | Zimices                                                                                                                                                                              |
| 388 |     18.395948 |     93.044822 | Richard J. Harris                                                                                                                                                                    |
| 389 |   1002.882743 |     44.335088 | NA                                                                                                                                                                                   |
| 390 |    632.572733 |     11.758656 | Michelle Site                                                                                                                                                                        |
| 391 |    906.258949 |    303.054545 | Kamil S. Jaron                                                                                                                                                                       |
| 392 |    537.082588 |    182.555688 | Natasha Vitek                                                                                                                                                                        |
| 393 |    493.994182 |    768.941719 | Mo Hassan                                                                                                                                                                            |
| 394 |    791.575824 |    118.527574 | NA                                                                                                                                                                                   |
| 395 |    277.080735 |     19.711948 | Matt Crook                                                                                                                                                                           |
| 396 |    313.620453 |    480.716173 | Margot Michaud                                                                                                                                                                       |
| 397 |    537.005775 |     23.693483 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 398 |    458.342148 |    604.229120 | Michelle Site                                                                                                                                                                        |
| 399 |   1000.640010 |    670.459568 | Margot Michaud                                                                                                                                                                       |
| 400 |    841.354301 |    481.165605 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 401 |    456.166627 |    558.480242 | Maxime Dahirel                                                                                                                                                                       |
| 402 |    855.443825 |    115.344610 | Birgit Lang                                                                                                                                                                          |
| 403 |    629.964052 |    763.519502 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                             |
| 404 |    895.840041 |    131.784758 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 405 |    880.059439 |    683.759797 | Chris huh                                                                                                                                                                            |
| 406 |    246.546688 |    115.367100 | Steven Traver                                                                                                                                                                        |
| 407 |    572.577529 |    276.670290 | Chris huh                                                                                                                                                                            |
| 408 |    847.223629 |    533.434849 | Matt Crook                                                                                                                                                                           |
| 409 |    361.578770 |    306.982974 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 410 |    234.144583 |    688.667354 | Kamil S. Jaron                                                                                                                                                                       |
| 411 |   1012.980347 |     66.188214 | Kai R. Caspar                                                                                                                                                                        |
| 412 |    486.512086 |    603.980335 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                                    |
| 413 |    282.668825 |    426.589241 | Tauana J. Cunha                                                                                                                                                                      |
| 414 |     62.461365 |    797.119707 | Margot Michaud                                                                                                                                                                       |
| 415 |    530.126536 |     35.365055 | Chris huh                                                                                                                                                                            |
| 416 |    776.143193 |    592.078278 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 417 |    907.131523 |    259.782481 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 418 |    227.437321 |    714.909078 | Blair Perry                                                                                                                                                                          |
| 419 |    720.022270 |    341.935423 | CNZdenek                                                                                                                                                                             |
| 420 |    749.182575 |    728.880968 | Jakovche                                                                                                                                                                             |
| 421 |     57.527768 |    290.528101 | Caleb M. Brown                                                                                                                                                                       |
| 422 |    160.293201 |    422.681551 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 423 |    983.434297 |    749.631500 | M. A. Broussard                                                                                                                                                                      |
| 424 |    803.902775 |    376.023887 | Tracy A. Heath                                                                                                                                                                       |
| 425 |    127.265063 |    297.341588 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 426 |    205.502968 |    335.904965 | T. Tischler                                                                                                                                                                          |
| 427 |   1001.259305 |     88.825550 | Shyamal                                                                                                                                                                              |
| 428 |    336.208752 |     27.341125 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 429 |    430.365076 |    448.233085 | NA                                                                                                                                                                                   |
| 430 |    453.274375 |    497.324010 | Ferran Sayol                                                                                                                                                                         |
| 431 |    148.673716 |    520.404807 | Chris huh                                                                                                                                                                            |
| 432 |    980.214146 |    762.105381 | Scott Hartman                                                                                                                                                                        |
| 433 |    470.136860 |    753.311882 | T. Michael Keesey                                                                                                                                                                    |
| 434 |    256.769761 |    393.931746 | Birgit Lang                                                                                                                                                                          |
| 435 |    576.720443 |    502.075498 | Tracy A. Heath                                                                                                                                                                       |
| 436 |    503.551645 |    637.724681 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 437 |    369.311346 |    676.299286 | Steven Traver                                                                                                                                                                        |
| 438 |   1010.587237 |     97.953115 | Matt Crook                                                                                                                                                                           |
| 439 |    218.255246 |    131.245385 | Scott Hartman                                                                                                                                                                        |
| 440 |    305.913176 |    678.786339 | FJDegrange                                                                                                                                                                           |
| 441 |    347.951464 |    351.977118 | Gareth Monger                                                                                                                                                                        |
| 442 |    442.093112 |    609.069218 | Scott Hartman                                                                                                                                                                        |
| 443 |     10.657638 |    580.598947 | Andrew A. Farke                                                                                                                                                                      |
| 444 |   1007.886229 |    393.505470 | Beth Reinke                                                                                                                                                                          |
| 445 |    967.002050 |    319.269782 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 446 |    943.989735 |    593.457506 | NA                                                                                                                                                                                   |
| 447 |    258.678947 |    793.762664 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                                        |
| 448 |    974.583127 |    383.296914 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                       |
| 449 |    730.656881 |    323.444545 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 450 |    843.857332 |    236.619534 | Matt Crook                                                                                                                                                                           |
| 451 |    850.573367 |     40.818303 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                                 |
| 452 |    334.426502 |    659.623846 | FunkMonk                                                                                                                                                                             |
| 453 |    864.389465 |    787.767654 | NA                                                                                                                                                                                   |
| 454 |    248.795691 |     91.746960 | NA                                                                                                                                                                                   |
| 455 |    565.613202 |     75.692761 | T. Michael Keesey                                                                                                                                                                    |
| 456 |    976.879780 |    117.605284 | Zimices                                                                                                                                                                              |
| 457 |    478.464820 |    694.352756 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 458 |   1014.897488 |     31.459074 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
| 459 |    872.214934 |    698.338069 | Neil Kelley                                                                                                                                                                          |
| 460 |    389.554194 |    727.205436 | Gareth Monger                                                                                                                                                                        |
| 461 |    427.417298 |    542.594681 | Michael P. Taylor                                                                                                                                                                    |
| 462 |    222.274442 |    729.205385 | Harold N Eyster                                                                                                                                                                      |
| 463 |    645.660852 |    360.751691 | Scott Hartman                                                                                                                                                                        |
| 464 |    319.286820 |    641.046631 | Harold N Eyster                                                                                                                                                                      |
| 465 |    252.594450 |    707.377048 | L. Shyamal                                                                                                                                                                           |
| 466 |     12.475880 |    340.856587 | Margot Michaud                                                                                                                                                                       |
| 467 |    613.054264 |    161.955438 | L. Shyamal                                                                                                                                                                           |
| 468 |    465.861707 |    634.788446 | Milton Tan                                                                                                                                                                           |
| 469 |    297.531301 |    520.005551 | T. Michael Keesey                                                                                                                                                                    |
| 470 |    845.165555 |    320.883305 | Steven Traver                                                                                                                                                                        |
| 471 |     70.655154 |    782.005443 | Gopal Murali                                                                                                                                                                         |
| 472 |    510.702036 |     64.831585 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                           |
| 473 |    260.049457 |    513.847217 | Ferran Sayol                                                                                                                                                                         |
| 474 |    524.429243 |     70.019470 | Andrew A. Farke                                                                                                                                                                      |
| 475 |    622.969848 |    431.905672 | Ferran Sayol                                                                                                                                                                         |
| 476 |    623.767704 |    532.988310 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 477 |    702.954995 |    788.805207 | Tyler Greenfield                                                                                                                                                                     |
| 478 |    957.653837 |    790.642552 | Steven Traver                                                                                                                                                                        |
| 479 |    681.585543 |     26.467712 | Matthew E. Clapham                                                                                                                                                                   |
| 480 |    168.363742 |     66.624944 | NASA                                                                                                                                                                                 |
| 481 |     83.720138 |    155.999275 | Ingo Braasch                                                                                                                                                                         |
| 482 |    155.619565 |    100.316552 | Matt Crook                                                                                                                                                                           |
| 483 |    217.587948 |    445.004054 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 484 |    964.697699 |    567.712941 | Dmitry Bogdanov                                                                                                                                                                      |
| 485 |    985.024721 |    680.762488 | Zimices                                                                                                                                                                              |
| 486 |    984.749334 |    697.647634 | Steven Traver                                                                                                                                                                        |
| 487 |    203.142279 |    735.626000 | Gareth Monger                                                                                                                                                                        |
| 488 |    378.377121 |    768.176723 | Steven Traver                                                                                                                                                                        |
| 489 |    945.565652 |    434.286977 | Pete Buchholz                                                                                                                                                                        |
| 490 |    712.331306 |    468.007720 | Joanna Wolfe                                                                                                                                                                         |
| 491 |    539.254965 |    705.178692 | Steven Traver                                                                                                                                                                        |
| 492 |   1005.709897 |    137.765056 | T. Michael Keesey                                                                                                                                                                    |
| 493 |     82.914955 |    468.540050 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 494 |     23.617324 |     17.037780 | Alexandre Vong                                                                                                                                                                       |
| 495 |    536.144903 |    377.024247 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 496 |    910.705178 |    141.075903 | M Kolmann                                                                                                                                                                            |
| 497 |    554.240643 |    554.534083 | Anthony Caravaggi                                                                                                                                                                    |
| 498 |    787.931176 |    325.892228 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
| 499 |    278.308109 |    757.817763 | Gareth Monger                                                                                                                                                                        |
| 500 |     13.660385 |    475.538254 | Chris huh                                                                                                                                                                            |
| 501 |    571.265044 |    558.158132 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                       |
| 502 |    720.120308 |     16.760495 | Robert Gay                                                                                                                                                                           |
| 503 |    589.361375 |    739.948295 | Zimices                                                                                                                                                                              |
| 504 |    802.182545 |    754.398798 | Gopal Murali                                                                                                                                                                         |
| 505 |    277.566608 |    574.497100 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 506 |    442.952554 |    786.538513 | Shyamal                                                                                                                                                                              |
| 507 |    126.639240 |    304.712469 | Margot Michaud                                                                                                                                                                       |
| 508 |   1015.689917 |    656.365396 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 509 |    447.502310 |    737.299205 | Steven Traver                                                                                                                                                                        |
| 510 |    590.350631 |    789.648015 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 511 |    477.548072 |    411.379278 | Christoph Schomburg                                                                                                                                                                  |
| 512 |    773.376929 |    574.688150 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 513 |     49.594133 |    316.745021 | Steven Traver                                                                                                                                                                        |
| 514 |    172.156576 |    312.227422 | Ben Liebeskind                                                                                                                                                                       |
| 515 |    568.566510 |    181.861340 | Margot Michaud                                                                                                                                                                       |
| 516 |    982.120122 |    789.825905 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 517 |     57.600453 |    687.916176 | Steven Traver                                                                                                                                                                        |
| 518 |    227.849048 |    780.781826 | Zimices                                                                                                                                                                              |
| 519 |    746.858664 |    315.183261 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 520 |    490.207541 |    657.425483 | Kai R. Caspar                                                                                                                                                                        |
| 521 |    807.031280 |    548.624507 | Ferran Sayol                                                                                                                                                                         |
| 522 |    663.009888 |    419.671097 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 523 |    304.366748 |      9.001704 | Bryan Carstens                                                                                                                                                                       |
| 524 |    912.218666 |    425.447591 | Matt Crook                                                                                                                                                                           |
| 525 |    451.562199 |    721.484454 | David Tana                                                                                                                                                                           |
| 526 |    840.502872 |     16.512339 | Ferran Sayol                                                                                                                                                                         |
| 527 |    254.242873 |     78.208234 | NA                                                                                                                                                                                   |
| 528 |    355.377976 |    275.121094 | kotik                                                                                                                                                                                |
| 529 |    660.160615 |    168.691692 | NA                                                                                                                                                                                   |
| 530 |    741.638594 |      8.121593 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 531 |    575.735334 |     20.272951 | Kent Elson Sorgon                                                                                                                                                                    |
| 532 |    947.557347 |    375.080096 | Steven Traver                                                                                                                                                                        |
| 533 |    569.244265 |    593.042414 | Sarah Alewijnse                                                                                                                                                                      |
| 534 |    192.390769 |    123.054984 | NA                                                                                                                                                                                   |
| 535 |    667.881547 |    121.753296 | Andrew A. Farke                                                                                                                                                                      |
| 536 |    971.281377 |    266.236222 | Steven Traver                                                                                                                                                                        |
| 537 |    395.417753 |    253.767139 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 538 |   1016.198698 |    237.296031 | Catherine Yasuda                                                                                                                                                                     |
| 539 |    428.885408 |    420.656108 | Zimices                                                                                                                                                                              |
| 540 |      6.524643 |     19.816755 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 541 |    203.047534 |    661.459211 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 542 |    280.970120 |    700.704040 | Zimices                                                                                                                                                                              |
| 543 |    185.371137 |    788.545306 | Ferran Sayol                                                                                                                                                                         |
| 544 |    914.684868 |     44.332605 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 545 |    869.484100 |     29.372335 | T. Michael Keesey                                                                                                                                                                    |
| 546 |    488.693359 |    624.875112 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 547 |    438.353552 |    226.672507 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
| 548 |    781.225464 |    366.947766 | Lukasiniho                                                                                                                                                                           |
| 549 |    308.893506 |    321.354036 | Steven Traver                                                                                                                                                                        |
| 550 |    721.173980 |    282.862045 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 551 |    115.795352 |    763.281692 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 552 |    642.863683 |    403.968821 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
| 553 |    882.962390 |    724.169427 | Jagged Fang Designs                                                                                                                                                                  |
| 554 |    991.227341 |    278.332933 | Chris huh                                                                                                                                                                            |
| 555 |    901.382416 |    563.212886 | Tasman Dixon                                                                                                                                                                         |
| 556 |    898.769793 |    235.585614 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 557 |    282.499005 |    482.700121 | Jaime Headden                                                                                                                                                                        |
| 558 |    192.360636 |     34.107208 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                                |
| 559 |     51.323810 |    564.441367 | Gareth Monger                                                                                                                                                                        |
| 560 |    217.063683 |    537.178328 | Zimices                                                                                                                                                                              |
| 561 |    290.663611 |    765.870690 | NA                                                                                                                                                                                   |
| 562 |    847.932229 |    782.100970 | B Kimmel                                                                                                                                                                             |
| 563 |    508.710986 |    460.468250 | Matt Martyniuk                                                                                                                                                                       |
| 564 |    645.464989 |    697.305916 | Chloé Schmidt                                                                                                                                                                        |
| 565 |    936.582523 |    227.719400 | Margot Michaud                                                                                                                                                                       |
| 566 |   1014.536447 |    474.324083 | NA                                                                                                                                                                                   |
| 567 |    671.917513 |    332.195046 | Matt Crook                                                                                                                                                                           |
| 568 |    181.409176 |    245.416542 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 569 |    198.399872 |    622.024794 | Joanna Wolfe                                                                                                                                                                         |
| 570 |     15.452176 |    145.675613 | Steven Traver                                                                                                                                                                        |
| 571 |    358.669863 |    339.734413 | Collin Gross                                                                                                                                                                         |
| 572 |   1007.432416 |    737.095577 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 573 |    295.096425 |    700.298282 | Christine Axon                                                                                                                                                                       |
| 574 |    137.631948 |    623.304166 | Zimices                                                                                                                                                                              |
| 575 |    973.092001 |    594.491041 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 576 |     17.898469 |     77.654144 | Katie S. Collins                                                                                                                                                                     |
| 577 |     19.826183 |    539.612496 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 578 |    559.601963 |    290.579143 | Matt Crook                                                                                                                                                                           |
| 579 |    510.650329 |    342.718045 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 580 |    172.448316 |    205.793189 | Jagged Fang Designs                                                                                                                                                                  |
| 581 |    215.602346 |    432.325166 | Ferran Sayol                                                                                                                                                                         |
| 582 |    907.393287 |    785.085176 | Rainer Schoch                                                                                                                                                                        |
| 583 |    889.641473 |     38.560953 | L. Shyamal                                                                                                                                                                           |
| 584 |    140.925107 |    384.691650 | Matt Crook                                                                                                                                                                           |
| 585 |   1012.934670 |    180.522559 | Steven Traver                                                                                                                                                                        |
| 586 |     57.685250 |    674.408454 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 587 |    798.045356 |    245.951881 | Matt Crook                                                                                                                                                                           |
| 588 |    223.980358 |    392.611758 | Kai R. Caspar                                                                                                                                                                        |
| 589 |     37.905879 |    577.700720 | Inessa Voet                                                                                                                                                                          |
| 590 |    335.777693 |     48.670145 | Jiekun He                                                                                                                                                                            |
| 591 |    840.013510 |    365.844948 | Caleb Brown                                                                                                                                                                          |
| 592 |    276.865714 |    593.247202 | Steven Coombs                                                                                                                                                                        |
| 593 |    890.335130 |    266.312878 | FunkMonk                                                                                                                                                                             |
| 594 |    884.112003 |    549.936154 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 595 |    747.597590 |    218.761854 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 596 |    601.954555 |    228.586834 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 597 |   1015.907104 |    441.192498 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 598 |    688.533654 |    531.687412 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
| 599 |    997.533389 |    482.267983 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 600 |    146.556119 |    201.775722 | Gareth Monger                                                                                                                                                                        |
| 601 |     19.124785 |    503.671794 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 602 |     45.948792 |    388.371994 | Matt Crook                                                                                                                                                                           |
| 603 |    197.702148 |    467.236579 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 604 |    291.030943 |    440.778760 | Kamil S. Jaron                                                                                                                                                                       |
| 605 |    745.909566 |    609.498496 | Michael Scroggie                                                                                                                                                                     |
| 606 |    845.922406 |    281.871724 | Alex Slavenko                                                                                                                                                                        |
| 607 |     21.367847 |    791.228251 | Gareth Monger                                                                                                                                                                        |
| 608 |    871.872006 |    545.315517 | Burton Robert, USFWS                                                                                                                                                                 |
| 609 |    458.689756 |    744.839894 | Margot Michaud                                                                                                                                                                       |
| 610 |    948.957695 |    733.930210 | Margot Michaud                                                                                                                                                                       |
| 611 |    649.519534 |    426.185608 | Scott Hartman                                                                                                                                                                        |
| 612 |    297.939955 |    643.676121 | Jagged Fang Designs                                                                                                                                                                  |
| 613 |    790.787612 |    605.512702 | Chris huh                                                                                                                                                                            |
| 614 |     52.045697 |    700.010630 | Jimmy Bernot                                                                                                                                                                         |
| 615 |    557.369273 |    350.928943 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                               |
| 616 |     54.422833 |    282.008099 | Kamil S. Jaron                                                                                                                                                                       |
| 617 |    221.798480 |    267.110621 | Gareth Monger                                                                                                                                                                        |
| 618 |    455.588939 |    460.231407 | Sarah Werning                                                                                                                                                                        |
| 619 |    418.052389 |    397.323532 | Iain Reid                                                                                                                                                                            |
| 620 |    219.135648 |    582.950239 | Margot Michaud                                                                                                                                                                       |
| 621 |    299.969980 |    734.703143 | Xavier Giroux-Bougard                                                                                                                                                                |
| 622 |    573.705975 |    609.974071 | Tasman Dixon                                                                                                                                                                         |
| 623 |    608.745671 |    260.449518 | Pete Buchholz                                                                                                                                                                        |
| 624 |    180.424428 |    634.792787 | Michelle Site                                                                                                                                                                        |
| 625 |     34.656136 |    293.603217 | Steven Traver                                                                                                                                                                        |
| 626 |    163.258148 |    668.687092 | Alex Slavenko                                                                                                                                                                        |
| 627 |     59.440499 |    221.408557 | Dean Schnabel                                                                                                                                                                        |
| 628 |    593.228980 |    462.321384 | Gareth Monger                                                                                                                                                                        |
| 629 |     36.466530 |    595.566398 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 630 |    156.856635 |    122.306088 | Manabu Sakamoto                                                                                                                                                                      |
| 631 |    876.923735 |    146.813728 | Matt Crook                                                                                                                                                                           |
| 632 |    135.207951 |    616.778990 | Gareth Monger                                                                                                                                                                        |
| 633 |    423.475882 |    518.457297 | T. Michael Keesey                                                                                                                                                                    |
| 634 |    260.884275 |    226.830944 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 635 |     24.989965 |    603.712336 | kotik                                                                                                                                                                                |
| 636 |     56.315695 |    628.670991 | NA                                                                                                                                                                                   |
| 637 |    742.090769 |    790.572060 | Chris huh                                                                                                                                                                            |
| 638 |    596.225908 |     70.008451 | Zimices                                                                                                                                                                              |
| 639 |    798.086211 |    444.685568 | NA                                                                                                                                                                                   |
| 640 |     20.955736 |    587.429164 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 641 |    741.947188 |    322.720185 | Tasman Dixon                                                                                                                                                                         |
| 642 |    794.321191 |    264.702744 | Matt Crook                                                                                                                                                                           |
| 643 |    613.962708 |    118.040678 | Gareth Monger                                                                                                                                                                        |
| 644 |    864.949579 |    411.377358 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                                  |
| 645 |    632.113021 |    141.579659 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 646 |    931.100056 |    130.337750 | Scott Hartman                                                                                                                                                                        |
| 647 |    952.882948 |    748.637802 | Maija Karala                                                                                                                                                                         |
| 648 |    230.049518 |    113.986604 | Tauana J. Cunha                                                                                                                                                                      |
| 649 |    290.200682 |    564.124967 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                      |
| 650 |    173.312797 |    797.017598 | Birgit Lang                                                                                                                                                                          |
| 651 |    597.196099 |      6.784979 | SauropodomorphMonarch                                                                                                                                                                |
| 652 |     12.797995 |    486.493117 | Shyamal                                                                                                                                                                              |
| 653 |    848.682337 |    727.138073 | Gareth Monger                                                                                                                                                                        |
| 654 |     47.240974 |    666.948840 | Jimmy Bernot                                                                                                                                                                         |
| 655 |     13.998380 |    111.171979 | Scott Hartman                                                                                                                                                                        |
| 656 |    340.217495 |    449.380265 | Margot Michaud                                                                                                                                                                       |
| 657 |    116.090279 |    326.957508 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 658 |    910.197403 |    125.039972 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 659 |    575.978369 |    696.367784 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 660 |    268.338454 |    621.125751 | Margot Michaud                                                                                                                                                                       |
| 661 |    990.827075 |    156.904602 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 662 |    819.037683 |    551.621172 | Anilocra (vectorization by Yan Wong)                                                                                                                                                 |
| 663 |    356.670996 |    735.955134 | Steven Traver                                                                                                                                                                        |
| 664 |    150.306098 |    411.497952 | Tasman Dixon                                                                                                                                                                         |
| 665 |    931.144734 |    583.343042 | Matt Crook                                                                                                                                                                           |
| 666 |    571.153919 |     12.149484 | Smokeybjb                                                                                                                                                                            |
| 667 |    138.431610 |    634.363945 | Noah Schlottman                                                                                                                                                                      |
| 668 |    153.172739 |    615.819092 | Melissa Broussard                                                                                                                                                                    |
| 669 |    681.621705 |    128.731550 | Matt Martyniuk                                                                                                                                                                       |
| 670 |    383.194076 |    785.319734 | Zimices                                                                                                                                                                              |
| 671 |    592.435771 |    443.192819 | T. Michael Keesey                                                                                                                                                                    |
| 672 |    428.845577 |    264.649329 | Matt Crook                                                                                                                                                                           |
| 673 |    819.342424 |    316.923031 | Birgit Lang                                                                                                                                                                          |
| 674 |    416.099320 |    342.236324 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 675 |    851.286679 |    513.400910 | Rebecca Groom                                                                                                                                                                        |
| 676 |    121.102079 |    128.668280 | Zimices                                                                                                                                                                              |
| 677 |    768.699234 |    335.328315 | Smokeybjb                                                                                                                                                                            |
| 678 |     35.631653 |     64.886157 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 679 |    464.221490 |    333.179766 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 680 |    848.268113 |    296.357742 | Manabu Sakamoto                                                                                                                                                                      |
| 681 |    317.353267 |     29.403348 | Jessica Anne Miller                                                                                                                                                                  |
| 682 |    198.970408 |    133.621624 | Gopal Murali                                                                                                                                                                         |
| 683 |     15.195329 |    669.462689 | Tauana J. Cunha                                                                                                                                                                      |
| 684 |    106.854681 |    100.589803 | Gareth Monger                                                                                                                                                                        |
| 685 |    761.464697 |      9.586101 | Matt Crook                                                                                                                                                                           |
| 686 |    413.157244 |    530.522034 | Zimices                                                                                                                                                                              |
| 687 |    176.437070 |    767.297416 | CNZdenek                                                                                                                                                                             |
| 688 |    191.527411 |    312.250839 | Anilocra (vectorization by Yan Wong)                                                                                                                                                 |
| 689 |    364.559348 |    395.061977 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 690 |     82.556130 |    125.080017 | Tasman Dixon                                                                                                                                                                         |
| 691 |     67.441658 |     14.615893 | Gareth Monger                                                                                                                                                                        |
| 692 |    907.943534 |    343.892600 | Dean Schnabel                                                                                                                                                                        |
| 693 |    972.212224 |    663.101078 | Maxime Dahirel                                                                                                                                                                       |
| 694 |    573.430376 |    442.302849 | Kamil S. Jaron                                                                                                                                                                       |
| 695 |    283.700028 |    452.835054 | Abraão B. Leite                                                                                                                                                                      |
| 696 |    848.691467 |    656.570627 | T. Michael Keesey (after C. De Muizon)                                                                                                                                               |
| 697 |    504.127492 |     48.457057 | Ferran Sayol                                                                                                                                                                         |
| 698 |    696.775124 |    482.091033 | Matt Crook                                                                                                                                                                           |
| 699 |     17.858637 |    650.291779 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 700 |    579.469589 |    489.368430 | Nobu Tamura                                                                                                                                                                          |
| 701 |   1003.215123 |    309.988927 | Jaime Headden                                                                                                                                                                        |
| 702 |    128.457610 |    280.084641 | Alexandra van der Geer                                                                                                                                                               |
| 703 |    255.304019 |    263.856213 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                             |
| 704 |    946.471680 |    359.185204 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 705 |    702.886115 |     41.089393 | Chris huh                                                                                                                                                                            |
| 706 |    663.098906 |    101.798686 | Zimices                                                                                                                                                                              |
| 707 |    902.733178 |    249.456153 | Matt Crook                                                                                                                                                                           |
| 708 |    139.829116 |    705.169951 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 709 |    166.558206 |      9.332366 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 710 |     75.666953 |    669.599152 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 711 |    304.498291 |    249.528619 | T. Michael Keesey                                                                                                                                                                    |
| 712 |    510.793748 |    586.028159 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                           |
| 713 |    295.632616 |    511.368721 | Matt Crook                                                                                                                                                                           |
| 714 |    865.677520 |    505.424591 | T. Michael Keesey                                                                                                                                                                    |
| 715 |    573.184390 |    299.635300 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 716 |    558.040997 |    570.893240 | Margot Michaud                                                                                                                                                                       |
| 717 |     33.789030 |    432.956566 | Emily Willoughby                                                                                                                                                                     |
| 718 |    619.914417 |     14.478995 | Birgit Lang                                                                                                                                                                          |
| 719 |    796.346234 |    379.834497 | T. Michael Keesey                                                                                                                                                                    |
| 720 |    955.685357 |    541.404290 | NA                                                                                                                                                                                   |
| 721 |    659.853265 |    278.405559 | FunkMonk                                                                                                                                                                             |
| 722 |    678.102381 |      9.260380 | Ferran Sayol                                                                                                                                                                         |
| 723 |      9.364822 |    417.642559 | NA                                                                                                                                                                                   |
| 724 |    182.442309 |    279.015179 | Margot Michaud                                                                                                                                                                       |
| 725 |   1000.302342 |    627.086794 | NASA                                                                                                                                                                                 |
| 726 |    591.369882 |    677.088613 | Harold N Eyster                                                                                                                                                                      |
| 727 |     17.125058 |    575.210433 | Dean Schnabel                                                                                                                                                                        |
| 728 |    606.612620 |     97.903314 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 729 |    746.202232 |    622.185932 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 730 |    887.321564 |    271.883344 | Jagged Fang Designs                                                                                                                                                                  |
| 731 |    366.896464 |    783.334731 | Gareth Monger                                                                                                                                                                        |
| 732 |    993.222580 |    452.724388 | Tracy A. Heath                                                                                                                                                                       |
| 733 |    801.839566 |     66.164762 | NA                                                                                                                                                                                   |
| 734 |    608.401505 |    399.813664 | Margot Michaud                                                                                                                                                                       |
| 735 |    102.117127 |    675.387424 | Matt Crook                                                                                                                                                                           |
| 736 |    558.935120 |    318.603759 | Harold N Eyster                                                                                                                                                                      |
| 737 |    690.721659 |    108.228359 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 738 |    981.589129 |    419.987997 | Scott Hartman                                                                                                                                                                        |
| 739 |    768.307613 |    713.499906 | T. Michael Keesey                                                                                                                                                                    |
| 740 |    178.163999 |    598.494680 | Martin Kevil                                                                                                                                                                         |
| 741 |    218.531724 |    680.643481 | Jagged Fang Designs                                                                                                                                                                  |
| 742 |    806.722747 |    298.126411 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 743 |     21.244015 |    270.236267 | Scott Hartman                                                                                                                                                                        |
| 744 |    949.963792 |    516.051576 | Rebecca Groom                                                                                                                                                                        |
| 745 |    886.130792 |    246.460479 | Ferran Sayol                                                                                                                                                                         |
| 746 |    290.524596 |    368.531418 | Margot Michaud                                                                                                                                                                       |
| 747 |    351.371883 |    225.433514 | Emily Willoughby                                                                                                                                                                     |
| 748 |     96.225816 |    437.263017 | Chris huh                                                                                                                                                                            |
| 749 |     61.379430 |    197.002888 | Tracy A. Heath                                                                                                                                                                       |
| 750 |    888.454642 |    203.639826 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 751 |    776.801238 |    453.722101 | Christine Axon                                                                                                                                                                       |
| 752 |     48.157304 |    645.085667 | Zimices                                                                                                                                                                              |
| 753 |    560.736210 |    722.856238 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 754 |    470.348242 |    442.524977 | Melissa Broussard                                                                                                                                                                    |
| 755 |    136.198595 |     10.628732 | Gopal Murali                                                                                                                                                                         |
| 756 |    685.950277 |    594.569820 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 757 |     28.826459 |    724.137587 | Anthony Caravaggi                                                                                                                                                                    |
| 758 |    591.746455 |    297.573507 | Zimices                                                                                                                                                                              |
| 759 |    905.639457 |    213.064547 | Matt Crook                                                                                                                                                                           |
| 760 |    504.989171 |    603.790933 | Sarah Werning                                                                                                                                                                        |
| 761 |    924.708999 |    770.009960 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 762 |    411.678252 |    716.152809 | Katie S. Collins                                                                                                                                                                     |
| 763 |    355.669587 |    416.384323 | Margot Michaud                                                                                                                                                                       |
| 764 |    713.072738 |    352.605293 | Jack Mayer Wood                                                                                                                                                                      |
| 765 |    856.740349 |    696.999073 | Lukasiniho                                                                                                                                                                           |
| 766 |    861.937974 |    669.919076 | Tasman Dixon                                                                                                                                                                         |
| 767 |   1005.525763 |    346.841587 | Matt Crook                                                                                                                                                                           |
| 768 |    713.881948 |    540.437102 | Margot Michaud                                                                                                                                                                       |
| 769 |    151.039926 |    551.801190 | Zimices                                                                                                                                                                              |
| 770 |    801.814834 |    571.420859 | Mo Hassan                                                                                                                                                                            |
| 771 |    299.501384 |    431.145837 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 772 |    580.533679 |    527.134253 | Ferran Sayol                                                                                                                                                                         |
| 773 |     50.780378 |    133.308658 | Zimices                                                                                                                                                                              |
| 774 |    188.759745 |    269.540154 | Sean McCann                                                                                                                                                                          |
| 775 |    436.093644 |    519.441979 | NA                                                                                                                                                                                   |
| 776 |     98.344334 |    564.524583 | Matt Crook                                                                                                                                                                           |
| 777 |    602.982544 |    216.651156 | Zimices                                                                                                                                                                              |
| 778 |    911.140388 |    331.992275 | Tauana J. Cunha                                                                                                                                                                      |
| 779 |     45.735297 |    492.948891 | CNZdenek                                                                                                                                                                             |
| 780 |    158.689739 |    490.025109 | Juan Carlos Jerí                                                                                                                                                                     |
| 781 |    203.939563 |    509.479529 | Matt Crook                                                                                                                                                                           |
| 782 |    155.895927 |    752.593200 | Peter Coxhead                                                                                                                                                                        |
| 783 |    228.787194 |    644.689401 | Maija Karala                                                                                                                                                                         |
| 784 |    768.109223 |    384.276657 | Zimices                                                                                                                                                                              |
| 785 |    608.298466 |    468.137868 | Eric Moody                                                                                                                                                                           |
| 786 |    264.015661 |     67.288732 | Mathew Wedel                                                                                                                                                                         |
| 787 |     66.542296 |    489.838611 | NA                                                                                                                                                                                   |
| 788 |    392.817919 |     52.881004 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 789 |    957.187521 |    119.144873 | Margot Michaud                                                                                                                                                                       |
| 790 |     48.627742 |    711.758473 | Ludwik Gasiorowski                                                                                                                                                                   |
| 791 |    998.249362 |    103.895739 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
| 792 |    310.646551 |    213.210412 | Zimices                                                                                                                                                                              |
| 793 |    738.290055 |    426.829689 | Steven Traver                                                                                                                                                                        |
| 794 |     24.906575 |    620.805228 | Margot Michaud                                                                                                                                                                       |
| 795 |    507.551391 |    436.605301 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 796 |    918.445322 |    456.990851 | Maija Karala                                                                                                                                                                         |
| 797 |      7.871110 |    519.756691 | Matt Crook                                                                                                                                                                           |
| 798 |    237.617411 |    726.566755 | Kai R. Caspar                                                                                                                                                                        |
| 799 |    962.125893 |    699.215981 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 800 |    549.908481 |    336.448380 | Gareth Monger                                                                                                                                                                        |
| 801 |    961.978387 |    601.177732 | Beth Reinke                                                                                                                                                                          |
| 802 |    436.674970 |    597.654935 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 803 |    611.660538 |    111.343780 | Henry Lydecker                                                                                                                                                                       |
| 804 |    180.951991 |    311.971046 | Matt Crook                                                                                                                                                                           |
| 805 |    610.194823 |    761.870157 | Joanna Wolfe                                                                                                                                                                         |
| 806 |    786.876877 |     14.881198 | Abraão B. Leite                                                                                                                                                                      |
| 807 |    142.940795 |    418.080701 | Zimices                                                                                                                                                                              |
| 808 |    964.206295 |    371.426418 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 809 |    572.830487 |    168.973061 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 810 |    442.755574 |    796.468457 | Birgit Lang                                                                                                                                                                          |
| 811 |     16.775293 |    557.233711 | Yusan Yang                                                                                                                                                                           |
| 812 |    861.219339 |    578.212095 | Stacy Spensley (Modified)                                                                                                                                                            |
| 813 |   1007.559566 |    764.238270 | Matt Crook                                                                                                                                                                           |
| 814 |    579.633890 |     79.309545 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 815 |    837.514045 |    308.600026 | Beth Reinke                                                                                                                                                                          |
| 816 |    834.848638 |    461.831921 | Matt Hayes                                                                                                                                                                           |
| 817 |     10.872495 |    352.382642 | T. Michael Keesey                                                                                                                                                                    |
| 818 |    694.938657 |    272.836676 | Jagged Fang Designs                                                                                                                                                                  |
| 819 |    477.439500 |    454.087247 | Matt Crook                                                                                                                                                                           |
| 820 |    989.160956 |    590.018162 | Zimices                                                                                                                                                                              |
| 821 |    318.276528 |    301.893897 | Scott Hartman                                                                                                                                                                        |
| 822 |     19.167299 |    446.693473 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 823 |    668.397569 |    586.341934 | Jack Mayer Wood                                                                                                                                                                      |
| 824 |    245.608662 |    767.622529 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 825 |    342.768662 |    373.101104 | Margot Michaud                                                                                                                                                                       |
| 826 |    335.549974 |    245.518550 | Steven Traver                                                                                                                                                                        |
| 827 |    230.523534 |    701.689248 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 828 |    195.336023 |    582.579335 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 829 |    418.293480 |    360.031363 | Gareth Monger                                                                                                                                                                        |
| 830 |    161.925978 |    531.638207 | Michael Scroggie                                                                                                                                                                     |
| 831 |    156.307136 |    588.738697 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 832 |   1008.513573 |    787.238797 | Zimices                                                                                                                                                                              |
| 833 |    393.866860 |    405.434127 | Matt Crook                                                                                                                                                                           |
| 834 |    589.419354 |    722.222738 | Andrew A. Farke                                                                                                                                                                      |
| 835 |    983.874644 |    616.015849 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                                    |
| 836 |    641.978046 |    351.453565 | Scott Hartman                                                                                                                                                                        |
| 837 |    979.887936 |    127.572636 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                            |
| 838 |    827.354177 |     14.160456 | Zimices                                                                                                                                                                              |
| 839 |    257.932602 |    288.925216 | Mathilde Cordellier                                                                                                                                                                  |
| 840 |    998.540671 |    726.983901 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 841 |    638.352997 |    547.803647 | Chloé Schmidt                                                                                                                                                                        |
| 842 |    134.893643 |    755.532569 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 843 |    880.690466 |    117.910063 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 844 |    600.196534 |    211.193558 | Steven Coombs                                                                                                                                                                        |
| 845 |    537.516243 |    426.768595 | Matt Crook                                                                                                                                                                           |
| 846 |    773.937252 |    522.414816 | Peter Coxhead                                                                                                                                                                        |
| 847 |    751.738044 |    403.147394 | NA                                                                                                                                                                                   |
| 848 |    164.196232 |    337.743552 | NA                                                                                                                                                                                   |
| 849 |     27.055900 |      9.254949 | Jagged Fang Designs                                                                                                                                                                  |
| 850 |    135.802724 |    552.550721 | Zimices                                                                                                                                                                              |
| 851 |    273.444254 |    306.218938 | Anthony Caravaggi                                                                                                                                                                    |
| 852 |    953.147620 |    270.285843 | Mathilde Cordellier                                                                                                                                                                  |
| 853 |    162.971278 |    281.852930 | Tauana J. Cunha                                                                                                                                                                      |
| 854 |    584.985599 |    240.428168 | Gareth Monger                                                                                                                                                                        |
| 855 |    359.354436 |     26.745079 | Zimices                                                                                                                                                                              |
| 856 |    719.490061 |    758.650036 | Steven Traver                                                                                                                                                                        |
| 857 |    294.718246 |    590.713624 | Gareth Monger                                                                                                                                                                        |
| 858 |     54.903308 |    350.475939 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 859 |    574.216529 |    272.346325 | Margot Michaud                                                                                                                                                                       |
| 860 |    978.379201 |     23.204570 | Matt Dempsey                                                                                                                                                                         |
| 861 |    915.416750 |    366.252174 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 862 |    405.861335 |    428.872297 | T. Michael Keesey                                                                                                                                                                    |
| 863 |    614.381048 |    303.867450 | Margot Michaud                                                                                                                                                                       |
| 864 |    577.153390 |    668.888923 | Matt Crook                                                                                                                                                                           |
| 865 |     41.087956 |    470.257947 | Jonathan Wells                                                                                                                                                                       |
| 866 |     55.953434 |    119.508236 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 867 |    986.612508 |    732.686390 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 868 |    926.095063 |    209.279725 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 869 |    860.048088 |    613.682886 | Margot Michaud                                                                                                                                                                       |
| 870 |    405.343093 |    787.169699 | Matt Crook                                                                                                                                                                           |
| 871 |    568.238285 |    655.955100 | NA                                                                                                                                                                                   |
| 872 |    379.056378 |    245.424496 | Collin Gross                                                                                                                                                                         |
| 873 |    738.421996 |    506.349180 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 874 |    203.191194 |    153.344703 | Matt Crook                                                                                                                                                                           |
| 875 |    307.657460 |    488.470275 | Zimices                                                                                                                                                                              |
| 876 |    998.585421 |    190.148567 | NA                                                                                                                                                                                   |
| 877 |    671.736531 |    352.483076 | Darius Nau                                                                                                                                                                           |
| 878 |    298.312809 |     24.352636 | Steven Blackwood                                                                                                                                                                     |
| 879 |    107.054548 |    124.044145 | Beth Reinke                                                                                                                                                                          |
| 880 |    155.717792 |    438.708729 | Gareth Monger                                                                                                                                                                        |
| 881 |    327.210914 |    294.828547 | Kimberly Haddrell                                                                                                                                                                    |
| 882 |    912.859541 |    238.843686 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 883 |    437.528827 |    245.256438 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 884 |    806.277319 |    459.703610 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 885 |     79.864469 |    279.330553 | NA                                                                                                                                                                                   |
| 886 |     67.651702 |    128.447530 | Pedro de Siracusa                                                                                                                                                                    |
| 887 |     40.754499 |    443.744447 | Scott Hartman                                                                                                                                                                        |
| 888 |    260.360093 |    778.186785 | Inessa Voet                                                                                                                                                                          |
| 889 |    429.401408 |    569.103341 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 890 |    730.470713 |     19.534207 | Matt Crook                                                                                                                                                                           |
| 891 |    624.975749 |    685.221168 | Emily Willoughby                                                                                                                                                                     |
| 892 |    942.447465 |    145.094676 | Tauana J. Cunha                                                                                                                                                                      |
| 893 |     63.288491 |    326.717564 | David Orr                                                                                                                                                                            |
| 894 |      7.274381 |    621.534847 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 895 |    579.261557 |    420.708654 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 896 |    261.598325 |    604.055501 | NA                                                                                                                                                                                   |
| 897 |    153.477478 |    676.392226 | Margot Michaud                                                                                                                                                                       |
| 898 |    981.017308 |    401.665882 | Mark Witton                                                                                                                                                                          |
| 899 |    980.604333 |    395.042148 | Yan Wong                                                                                                                                                                             |
| 900 |    442.056293 |     58.977412 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 901 |    782.603684 |    581.395267 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 902 |    419.505516 |    257.450442 | Katie S. Collins                                                                                                                                                                     |
| 903 |    441.280614 |    219.540569 | Zimices                                                                                                                                                                              |
| 904 |    821.497941 |    576.158021 | Collin Gross                                                                                                                                                                         |
| 905 |    105.250476 |    487.595128 | Ferran Sayol                                                                                                                                                                         |
| 906 |    372.888807 |    699.164465 | Anthony Caravaggi                                                                                                                                                                    |
| 907 |    173.179861 |    106.558296 | Ferran Sayol                                                                                                                                                                         |
| 908 |    801.282601 |    393.044271 | Gareth Monger                                                                                                                                                                        |
| 909 |    723.407644 |     55.368228 | FunkMonk                                                                                                                                                                             |
| 910 |    575.070470 |    461.577822 | Christoph Schomburg                                                                                                                                                                  |
| 911 |     44.739676 |    413.038061 | T. Michael Keesey                                                                                                                                                                    |
| 912 |     78.808050 |    563.679087 | MPF (vectorized by T. Michael Keesey)                                                                                                                                                |
| 913 |    647.328762 |    706.069473 | Eric Moody                                                                                                                                                                           |
| 914 |    315.924479 |    654.537691 | Zimices                                                                                                                                                                              |
| 915 |    958.652508 |    433.080521 | FunkMonk                                                                                                                                                                             |
| 916 |     41.902265 |    272.528977 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                                    |
| 917 |    574.380460 |    760.354811 | FunkMonk                                                                                                                                                                             |
| 918 |    936.947485 |    386.628932 | T. Michael Keesey                                                                                                                                                                    |
| 919 |    428.478742 |     74.922123 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
| 920 |    728.511747 |    770.694584 | Zimices                                                                                                                                                                              |
| 921 |   1010.848263 |    582.649261 | Katie S. Collins                                                                                                                                                                     |
| 922 |    208.541973 |     15.024054 | Gareth Monger                                                                                                                                                                        |
| 923 |    346.823212 |    216.562893 | Zimices                                                                                                                                                                              |
| 924 |    556.306095 |    707.164802 | Javier Luque                                                                                                                                                                         |
| 925 |    136.337292 |    205.802229 | Scott Hartman                                                                                                                                                                        |

    #> Your tweet has been posted!
