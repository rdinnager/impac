
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

Lily Hughes, Steven Traver, L. Shyamal, Gabriela Palomo-Munoz, Matus
Valach, Chris huh, Sarah Werning, Gareth Monger, Pete Buchholz, Maija
Karala, Kamil S. Jaron, Harold N Eyster, David Orr, Jimmy Bernot, Mattia
Menchetti, annaleeblysse, Milton Tan, xgirouxb, Tracy A. Heath,
Alexander Schmidt-Lebuhn, Zimices, Jaime A. Headden (vectorized by T.
Michael Keesey), Kent Elson Sorgon, Sarefo (vectorized by T. Michael
Keesey), Alexandre Vong, Javier Luque & Sarah Gerken, Beth Reinke, H. F.
O. March (vectorized by T. Michael Keesey), Matt Crook, Scott Hartman,
David Liao, Shyamal, Nicolas Mongiardino Koch, Dann Pigdon, Inessa Voet,
Steven Coombs, Jagged Fang Designs, T. Michael Keesey, Lukasiniho, ,
Scott Hartman (vectorized by T. Michael Keesey), Martin R. Smith, Pranav
Iyer (grey ideas), Emily Jane McTavish, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Emily Willoughby, Margot Michaud, Estelle Bourdon,
Chris Jennings (Risiatto), Noah Schlottman, photo from Casey Dunn, M
Kolmann, Mateus Zica (modified by T. Michael Keesey), Philip Chalmers
(vectorized by T. Michael Keesey), Caleb M. Brown, Andrew A. Farke,
Ferran Sayol, CNZdenek, Melissa Broussard, Tyler Greenfield, Frank
Förster (based on a picture by Jerry Kirkhart; modified by T. Michael
Keesey), Tasman Dixon, Michelle Site, Birgit Lang, Yan Wong from
illustration by Charles Orbigny, Roberto Diaz Sibaja, based on Domser,
(unknown), Nobu Tamura, Yan Wong, Crystal Maier, Collin Gross,
Ghedoghedo (vectorized by T. Michael Keesey), Almandine (vectorized by
T. Michael Keesey), Peileppe, Sidney Frederic Harmer, Arthur Everett
Shipley (vectorized by Maxime Dahirel), Nobu Tamura (vectorized by T.
Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Andreas Hejnol, Dean
Schnabel, Mathilde Cordellier, Maxime Dahirel, Anthony Caravaggi,
Benchill, Jaime Headden, I. Geoffroy Saint-Hilaire (vectorized by T.
Michael Keesey), Christine Axon, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, Matt Celeskey, Carlos
Cano-Barbacil, Jack Mayer Wood, Karl Ragnar Gjertsen (vectorized by T.
Michael Keesey), Lukas Panzarin, Alex Slavenko, C. Camilo
Julián-Caballero, Mali’o Kodis, image from the Smithsonian Institution,
T. Michael Keesey (after Mauricio Antón), Smokeybjb, Joanna Wolfe,
Dmitry Bogdanov, Zachary Quigley, Myriam\_Ramirez, Fir0002/Flagstaffotos
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Iain Reid, Mason McNair, Lafage, Owen Jones, Jordan Mallon
(vectorized by T. Michael Keesey), James R. Spotila and Ray Chatterji,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, NOAA Great
Lakes Environmental Research Laboratory (illustration) and Timothy J.
Bartley (silhouette), Ellen Edmonson and Hugh Chrisp (illustration) and
Timothy J. Bartley (silhouette), Nick Schooler, zoosnow, Hans Hillewaert
(vectorized by T. Michael Keesey), SauropodomorphMonarch, Kai R. Caspar,
Stanton F. Fink (vectorized by T. Michael Keesey), Sean McCann, Katie S.
Collins, Auckland Museum, Jaime Headden, modified by T. Michael Keesey,
Joe Schneid (vectorized by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Julia B McHugh, Michael Scroggie, Darren Naish
(vectorized by T. Michael Keesey), Daniel Stadtmauer, T. Michael Keesey
(vector) and Stuart Halliday (photograph), Mary Harrsch (modified by T.
Michael Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and
T. Michael Keesey., Bill Bouton (source photo) & T. Michael Keesey
(vectorization), Brad McFeeters (vectorized by T. Michael Keesey), Felix
Vaux, Falconaumanni and T. Michael Keesey, T. Michael Keesey
(vectorization) and HuttyMcphoo (photography), Robbie N. Cada (modified
by T. Michael Keesey), Dianne Bray / Museum Victoria (vectorized by T.
Michael Keesey), Dave Angelini, Renata F. Martins, Marmelad, Obsidian
Soul (vectorized by T. Michael Keesey), Nobu Tamura, vectorized by
Zimices, Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Ray Simpson (vectorized by T. Michael
Keesey), Sharon Wegner-Larsen, Patrick Fisher (vectorized by T. Michael
Keesey), T. Michael Keesey (photo by Bc999 \[Black crow\]), Mike Keesey
(vectorization) and Vaibhavcho (photography), Rebecca Groom, Yan Wong
from illustration by Jules Richard (1907), FunkMonk (Michael B. H.),
Chris A. Hamilton, Manabu Sakamoto, Christoph Schomburg, Cesar Julian,
Emma Kissling, Julio Garza, Jaime Chirinos (vectorized by T. Michael
Keesey), Matt Dempsey, DW Bapst (Modified from Bulman, 1964), Raven
Amos, Michael P. Taylor, Mali’o Kodis, photograph by John Slapcinsky,
FunkMonk, Richard Parker (vectorized by T. Michael Keesey), Steven
Haddock • Jellywatch.org, Farelli (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Mali’o Kodis, image from the
Biodiversity Heritage Library, SecretJellyMan - from Mason McNair,
Matthew E. Clapham, Jonathan Wells, Darren Naish (vectorize by T.
Michael Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Manabu Bessho-Uehara, (after Spotila 2004), Stuart Humphries,
Smokeybjb, vectorized by Zimices, Kenneth Lacovara (vectorized by T.
Michael Keesey), Davidson Sodré, Terpsichores, Bryan Carstens, B Kimmel,
Ingo Braasch, Mike Hanson, Ian Burt (original) and T. Michael Keesey
(vectorization), Tyler Greenfield and Scott Hartman, Nobu Tamura
(modified by T. Michael Keesey), Matt Wilkins (photo by Patrick
Kavanagh), Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Jean-Raphaël
Guillaumin (photography) and T. Michael Keesey (vectorization), Johan
Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Keith
Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, François Michonneau, Dein Freund der Baum (vectorized by
T. Michael Keesey), New York Zoological Society, T. Michael Keesey (from
a photo by Maximilian Paradiz), Noah Schlottman, Roberto Díaz Sibaja,
Tyler McCraney, George Edward Lodge (modified by T. Michael Keesey),
John Gould (vectorized by T. Michael Keesey), Juan Carlos Jerí, Alan
Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, B. Duygu Özpolat, Pearson Scott Foresman (vectorized by
T. Michael Keesey), Julien Louys, Jake Warner, Mali’o Kodis, photograph
by Cordell Expeditions at Cal Academy, V. Deepak, Nobu Tamura
(vectorized by A. Verrière), Frank Förster, Armin Reindl, Ernst Haeckel
(vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Conty (vectorized by T. Michael Keesey), Tauana J.
Cunha, Pollyanna von Knorring and T. Michael Keesey, Francesco
“Architetto” Rollandin, Joris van der Ham (vectorized by T. Michael
Keesey), Natasha Vitek, H. F. O. March (modified by T. Michael Keesey,
Michael P. Taylor & Matthew J. Wedel), Haplochromis (vectorized by T.
Michael Keesey), Dmitry Bogdanov (modified by T. Michael Keesey), Jerry
Oldenettel (vectorized by T. Michael Keesey), Ludwik Gasiorowski, Scott
Reid, Mark Hannaford (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Chloé Schmidt, Antonov (vectorized by T.
Michael Keesey), Danielle Alba, Xavier A. Jenkins, Gabriel Ugueto,
Fernando Carezzano, Lauren Anderson, Mali’o Kodis, image from Higgins
and Kristensen, 1986, Sam Fraser-Smith (vectorized by T. Michael
Keesey), Kailah Thorn & Mark Hutchinson, Michele M Tobias, Jay
Matternes, vectorized by Zimices, S.Martini, Chase Brownstein, Jon Hill,
Geoff Shaw, Walter Vladimir, Mathieu Basille, Zimices / Julián Bayona,
Richard Ruggiero, vectorized by Zimices, Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Philippe Janvier (vectorized by T.
Michael Keesey), Melissa Ingala, Matt Martyniuk, Trond R. Oskars, Todd
Marshall, vectorized by Zimices, T. Michael Keesey (after Marek
Velechovský), Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized
by T. Michael Keesey), Alexis Simon, Josefine Bohr Brask, Amanda Katzer,
Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Renato Santos,
Smokeybjb (modified by T. Michael Keesey), Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Mathew Wedel, Richard Lampitt, Jeremy Young /
NHM (vectorization by Yan Wong), Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Noah Schlottman,
photo by Museum of Geology, University of Tartu, Nina Skinner, Jiekun
He, Birgit Szabo, Vijay Cavale (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Matt Martyniuk (modified by T. Michael
Keesey), NASA, Caleb Brown

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    152.625138 |    359.436182 | Lily Hughes                                                                                                                                                           |
|   2 |    497.503641 |    619.595849 | Steven Traver                                                                                                                                                         |
|   3 |    349.883857 |    211.336605 | L. Shyamal                                                                                                                                                            |
|   4 |    735.718089 |    412.506595 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   5 |    237.090156 |    479.821436 | Matus Valach                                                                                                                                                          |
|   6 |    102.564683 |    263.142947 | Chris huh                                                                                                                                                             |
|   7 |    746.005118 |    108.796755 | Sarah Werning                                                                                                                                                         |
|   8 |    795.612030 |    325.382019 | L. Shyamal                                                                                                                                                            |
|   9 |    110.287609 |    587.301494 | Gareth Monger                                                                                                                                                         |
|  10 |    551.329786 |    270.637326 | Pete Buchholz                                                                                                                                                         |
|  11 |    509.204307 |     42.529953 | Maija Karala                                                                                                                                                          |
|  12 |    160.143705 |    699.662770 | Kamil S. Jaron                                                                                                                                                        |
|  13 |    928.792749 |    144.616414 | Harold N Eyster                                                                                                                                                       |
|  14 |    551.287153 |    417.776348 | David Orr                                                                                                                                                             |
|  15 |    739.412651 |    589.058418 | Steven Traver                                                                                                                                                         |
|  16 |     78.357927 |     32.979136 | Jimmy Bernot                                                                                                                                                          |
|  17 |    977.619992 |    514.683583 | Mattia Menchetti                                                                                                                                                      |
|  18 |    847.734912 |    498.555613 | annaleeblysse                                                                                                                                                         |
|  19 |    251.381401 |    540.972592 | Milton Tan                                                                                                                                                            |
|  20 |    683.155626 |    479.859224 | NA                                                                                                                                                                    |
|  21 |    946.588676 |    664.082255 | Steven Traver                                                                                                                                                         |
|  22 |     99.563769 |     65.341383 | xgirouxb                                                                                                                                                              |
|  23 |    843.825188 |    716.568612 | Tracy A. Heath                                                                                                                                                        |
|  24 |    279.705010 |    123.986156 | Steven Traver                                                                                                                                                         |
|  25 |     80.314229 |    145.370054 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  26 |    673.655616 |     23.682225 | Zimices                                                                                                                                                               |
|  27 |    776.654951 |    228.952855 | L. Shyamal                                                                                                                                                            |
|  28 |    435.753960 |    299.151632 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
|  29 |    399.768736 |    415.394364 | Kent Elson Sorgon                                                                                                                                                     |
|  30 |    558.103307 |    147.427598 | Zimices                                                                                                                                                               |
|  31 |    896.860972 |    335.401654 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
|  32 |     63.879030 |    501.407151 | Alexandre Vong                                                                                                                                                        |
|  33 |    179.546416 |    255.126505 | Javier Luque & Sarah Gerken                                                                                                                                           |
|  34 |    204.112287 |     88.090271 | NA                                                                                                                                                                    |
|  35 |    961.799314 |     46.206340 | Beth Reinke                                                                                                                                                           |
|  36 |    306.315693 |     49.458204 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
|  37 |    844.750502 |     27.519729 | Chris huh                                                                                                                                                             |
|  38 |    580.435281 |    214.174968 | Steven Traver                                                                                                                                                         |
|  39 |    593.603268 |    326.625644 | Matt Crook                                                                                                                                                            |
|  40 |    523.189610 |    776.573518 | Scott Hartman                                                                                                                                                         |
|  41 |    294.543123 |    426.003656 | Chris huh                                                                                                                                                             |
|  42 |    460.641074 |    109.831332 | David Liao                                                                                                                                                            |
|  43 |    479.154693 |    385.558685 | Shyamal                                                                                                                                                               |
|  44 |    316.967626 |    736.097268 | Nicolas Mongiardino Koch                                                                                                                                              |
|  45 |    945.794972 |    244.733721 | Dann Pigdon                                                                                                                                                           |
|  46 |    371.438977 |    354.650559 | Zimices                                                                                                                                                               |
|  47 |    217.919730 |    619.568267 | Inessa Voet                                                                                                                                                           |
|  48 |    966.994186 |    370.010443 | NA                                                                                                                                                                    |
|  49 |    824.994194 |    178.679592 | Steven Coombs                                                                                                                                                         |
|  50 |    660.591654 |    782.134689 | Jagged Fang Designs                                                                                                                                                   |
|  51 |     58.780271 |    729.048416 | Harold N Eyster                                                                                                                                                       |
|  52 |    650.605362 |    131.965679 | T. Michael Keesey                                                                                                                                                     |
|  53 |    682.301330 |    271.797339 | Lukasiniho                                                                                                                                                            |
|  54 |    794.545579 |    625.874064 |                                                                                                                                                                       |
|  55 |    112.760027 |    423.760120 | Matt Crook                                                                                                                                                            |
|  56 |    837.885040 |     64.819881 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
|  57 |    348.613983 |    489.969129 | Jagged Fang Designs                                                                                                                                                   |
|  58 |    748.907724 |    722.418114 | Martin R. Smith                                                                                                                                                       |
|  59 |    489.532805 |    485.620109 | Jagged Fang Designs                                                                                                                                                   |
|  60 |    173.667627 |    507.770764 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  61 |    141.527882 |     94.311420 | Emily Jane McTavish                                                                                                                                                   |
|  62 |    953.966935 |    774.045935 | NA                                                                                                                                                                    |
|  63 |    262.433131 |    401.609408 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  64 |    589.169135 |     56.550038 | Emily Willoughby                                                                                                                                                      |
|  65 |    392.459776 |    749.328184 | Margot Michaud                                                                                                                                                        |
|  66 |    450.015437 |    339.953496 | Estelle Bourdon                                                                                                                                                       |
|  67 |    907.173989 |    583.458713 | Chris Jennings (Risiatto)                                                                                                                                             |
|  68 |    397.800722 |    118.197927 | Margot Michaud                                                                                                                                                        |
|  69 |    473.590338 |     39.372292 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  70 |     24.433874 |    236.320392 | M Kolmann                                                                                                                                                             |
|  71 |    420.614034 |    268.791375 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
|  72 |    700.132613 |    327.161667 |                                                                                                                                                                       |
|  73 |    718.842541 |    532.938573 | Margot Michaud                                                                                                                                                        |
|  74 |    642.881688 |    179.263313 | NA                                                                                                                                                                    |
|  75 |    623.400384 |    419.832820 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
|  76 |    817.503234 |    499.290346 | Margot Michaud                                                                                                                                                        |
|  77 |    143.177819 |    174.192066 | Caleb M. Brown                                                                                                                                                        |
|  78 |    236.228845 |    742.166051 | Andrew A. Farke                                                                                                                                                       |
|  79 |    616.328753 |    729.856683 | Ferran Sayol                                                                                                                                                          |
|  80 |    938.335800 |    578.407968 | CNZdenek                                                                                                                                                              |
|  81 |    731.480425 |    572.253238 | Alexandre Vong                                                                                                                                                        |
|  82 |     32.362125 |    306.487366 | Matt Crook                                                                                                                                                            |
|  83 |    256.646814 |    224.511053 | Melissa Broussard                                                                                                                                                     |
|  84 |    963.163942 |    199.051439 | Tyler Greenfield                                                                                                                                                      |
|  85 |    798.869722 |    546.987047 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
|  86 |    191.728166 |    156.495437 | Jagged Fang Designs                                                                                                                                                   |
|  87 |    456.746636 |     34.188223 | Tasman Dixon                                                                                                                                                          |
|  88 |    113.342130 |    542.893035 | L. Shyamal                                                                                                                                                            |
|  89 |    522.726851 |    667.339510 | NA                                                                                                                                                                    |
|  90 |    276.756394 |    254.033893 | Michelle Site                                                                                                                                                         |
|  91 |     22.783814 |    377.367228 | Gareth Monger                                                                                                                                                         |
|  92 |    619.872499 |    659.149674 | Sarah Werning                                                                                                                                                         |
|  93 |    953.480325 |    574.067531 | Birgit Lang                                                                                                                                                           |
|  94 |    847.952402 |    676.626377 | Jagged Fang Designs                                                                                                                                                   |
|  95 |     15.007667 |    356.919690 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
|  96 |    753.413190 |    671.459497 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
|  97 |    975.662298 |    599.232298 | Matt Crook                                                                                                                                                            |
|  98 |    854.557470 |    141.487661 | Sarah Werning                                                                                                                                                         |
|  99 |    993.355827 |    446.274593 | Ferran Sayol                                                                                                                                                          |
| 100 |    426.114490 |    782.670527 | (unknown)                                                                                                                                                             |
| 101 |    276.338010 |    212.872814 | Nobu Tamura                                                                                                                                                           |
| 102 |   1005.482661 |    601.011885 | NA                                                                                                                                                                    |
| 103 |    429.746244 |    251.124897 | Steven Traver                                                                                                                                                         |
| 104 |     12.122337 |    162.262124 | Matt Crook                                                                                                                                                            |
| 105 |    407.179355 |    164.789463 | Ferran Sayol                                                                                                                                                          |
| 106 |     91.244669 |    234.900862 | Yan Wong                                                                                                                                                              |
| 107 |    317.091929 |    744.571930 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 108 |    689.077685 |    752.718193 | T. Michael Keesey                                                                                                                                                     |
| 109 |    290.626267 |    610.144858 | Crystal Maier                                                                                                                                                         |
| 110 |    868.249681 |    204.125278 | Scott Hartman                                                                                                                                                         |
| 111 |    703.960004 |    655.778011 | Andrew A. Farke                                                                                                                                                       |
| 112 |    812.218691 |    448.580630 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 113 |    686.104537 |    790.739884 | Collin Gross                                                                                                                                                          |
| 114 |    892.458576 |     11.678499 | Matt Crook                                                                                                                                                            |
| 115 |    654.335704 |    327.164077 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 116 |    882.205591 |    623.564193 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 117 |    402.641466 |     32.454684 | Crystal Maier                                                                                                                                                         |
| 118 |     93.140500 |    765.191615 | Margot Michaud                                                                                                                                                        |
| 119 |    192.380293 |    305.916501 | Peileppe                                                                                                                                                              |
| 120 |     63.877462 |     81.403005 | T. Michael Keesey                                                                                                                                                     |
| 121 |    105.937336 |    780.848018 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 122 |    695.466265 |     43.405945 | Ferran Sayol                                                                                                                                                          |
| 123 |    114.648106 |    227.352058 | Martin R. Smith                                                                                                                                                       |
| 124 |     34.647126 |    138.725467 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 125 |    319.897890 |    644.128552 | T. Michael Keesey                                                                                                                                                     |
| 126 |    392.367035 |    453.694854 | NA                                                                                                                                                                    |
| 127 |     31.870569 |    588.301349 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 128 |    405.599167 |    693.537160 | T. Michael Keesey                                                                                                                                                     |
| 129 |    260.469199 |    313.371476 | Andreas Hejnol                                                                                                                                                        |
| 130 |     61.390127 |    435.344642 | Steven Traver                                                                                                                                                         |
| 131 |    424.075501 |    216.156986 | Matt Crook                                                                                                                                                            |
| 132 |    726.557079 |    700.652317 | Steven Traver                                                                                                                                                         |
| 133 |     30.842257 |    746.288792 | Matt Crook                                                                                                                                                            |
| 134 |    478.904903 |    265.599241 | Dean Schnabel                                                                                                                                                         |
| 135 |     25.947094 |    717.899067 | Mathilde Cordellier                                                                                                                                                   |
| 136 |    262.982724 |    760.688792 | Zimices                                                                                                                                                               |
| 137 |    800.185883 |    583.012633 | Gareth Monger                                                                                                                                                         |
| 138 |    834.930458 |    771.219867 | Gareth Monger                                                                                                                                                         |
| 139 |    952.248773 |    532.505786 | Maxime Dahirel                                                                                                                                                        |
| 140 |    868.411308 |    600.371399 | Matt Crook                                                                                                                                                            |
| 141 |    716.429224 |     48.897893 | Kamil S. Jaron                                                                                                                                                        |
| 142 |    748.915168 |    469.638671 | Anthony Caravaggi                                                                                                                                                     |
| 143 |    903.823833 |    592.030641 | Benchill                                                                                                                                                              |
| 144 |    969.108581 |    454.837694 | Jaime Headden                                                                                                                                                         |
| 145 |    349.082099 |    123.866045 | L. Shyamal                                                                                                                                                            |
| 146 |    701.498105 |    757.305220 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 147 |    212.884004 |    668.242847 | Christine Axon                                                                                                                                                        |
| 148 |    797.591472 |    419.153065 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 149 |     45.451597 |    205.992912 | Chris huh                                                                                                                                                             |
| 150 |    501.315012 |    436.409279 | Chris huh                                                                                                                                                             |
| 151 |    709.483097 |    378.957900 | Zimices                                                                                                                                                               |
| 152 |    254.080473 |    591.014300 | Xavier Giroux-Bougard                                                                                                                                                 |
| 153 |    536.762371 |    450.261244 | Matt Celeskey                                                                                                                                                         |
| 154 |    917.962635 |    206.104662 | Steven Traver                                                                                                                                                         |
| 155 |    221.050920 |     96.208569 | T. Michael Keesey                                                                                                                                                     |
| 156 |    282.458759 |    335.235451 | Gareth Monger                                                                                                                                                         |
| 157 |    857.804453 |    158.010820 | Carlos Cano-Barbacil                                                                                                                                                  |
| 158 |    649.749269 |    377.124070 | Chris huh                                                                                                                                                             |
| 159 |    741.827313 |      3.674859 | Chris huh                                                                                                                                                             |
| 160 |    510.354780 |     86.004096 | Jack Mayer Wood                                                                                                                                                       |
| 161 |    647.948515 |    281.382186 | Yan Wong                                                                                                                                                              |
| 162 |     52.400493 |    382.380418 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 163 |    480.617833 |    185.305605 | Matt Crook                                                                                                                                                            |
| 164 |    938.760254 |    435.320476 | Zimices                                                                                                                                                               |
| 165 |    790.114214 |    513.942833 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 166 |    849.605761 |    293.759497 | Anthony Caravaggi                                                                                                                                                     |
| 167 |    178.338018 |    279.537210 | Lukas Panzarin                                                                                                                                                        |
| 168 |    302.550727 |    192.768649 | NA                                                                                                                                                                    |
| 169 |    948.583994 |    542.177245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 170 |     79.753498 |    135.119573 | Alex Slavenko                                                                                                                                                         |
| 171 |    337.303249 |    148.199441 | C. Camilo Julián-Caballero                                                                                                                                            |
| 172 |    837.697293 |    108.855194 | Ferran Sayol                                                                                                                                                          |
| 173 |    214.027499 |    757.022041 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 174 |    486.620633 |    464.576464 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 175 |    218.136719 |    280.514900 | Margot Michaud                                                                                                                                                        |
| 176 |    149.686315 |     15.362540 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 177 |    321.062972 |    465.553525 | Collin Gross                                                                                                                                                          |
| 178 |     32.986045 |    263.454621 | Yan Wong                                                                                                                                                              |
| 179 |    851.285896 |    252.453026 | T. Michael Keesey                                                                                                                                                     |
| 180 |    484.796481 |    737.190669 | NA                                                                                                                                                                    |
| 181 |    187.496944 |    198.356889 | Smokeybjb                                                                                                                                                             |
| 182 |    130.335162 |    545.060135 | Gareth Monger                                                                                                                                                         |
| 183 |    693.973748 |    645.972762 | Joanna Wolfe                                                                                                                                                          |
| 184 |    793.429956 |    473.450316 | Margot Michaud                                                                                                                                                        |
| 185 |    830.091205 |    465.832821 | Dmitry Bogdanov                                                                                                                                                       |
| 186 |    737.084507 |    443.843389 | Scott Hartman                                                                                                                                                         |
| 187 |    489.071904 |    755.556769 | Tasman Dixon                                                                                                                                                          |
| 188 |    748.559408 |    556.416345 | Anthony Caravaggi                                                                                                                                                     |
| 189 |    800.875755 |    362.319444 | Yan Wong                                                                                                                                                              |
| 190 |    509.253322 |    683.105600 | Zachary Quigley                                                                                                                                                       |
| 191 |    884.595626 |    565.224630 | Chris huh                                                                                                                                                             |
| 192 |     37.655031 |    473.826094 | Myriam\_Ramirez                                                                                                                                                       |
| 193 |    851.988712 |    379.133260 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 194 |    446.669804 |    235.220995 | NA                                                                                                                                                                    |
| 195 |    668.520510 |    112.754513 | Iain Reid                                                                                                                                                             |
| 196 |    420.349786 |    658.167306 | Mason McNair                                                                                                                                                          |
| 197 |    957.759078 |    796.798256 | Lafage                                                                                                                                                                |
| 198 |    589.191393 |    770.114892 | Owen Jones                                                                                                                                                            |
| 199 |   1012.833959 |    372.255006 | Gareth Monger                                                                                                                                                         |
| 200 |    238.500820 |    515.880348 | Chris huh                                                                                                                                                             |
| 201 |    831.317641 |    245.401673 | Steven Traver                                                                                                                                                         |
| 202 |    753.168366 |    502.202929 | Beth Reinke                                                                                                                                                           |
| 203 |   1000.985659 |    379.298560 | Michelle Site                                                                                                                                                         |
| 204 |    422.899192 |    437.125164 | Matt Crook                                                                                                                                                            |
| 205 |    330.724884 |    602.082367 | Scott Hartman                                                                                                                                                         |
| 206 |    346.087932 |    364.127917 | Ferran Sayol                                                                                                                                                          |
| 207 |    398.662662 |    173.800600 | Steven Coombs                                                                                                                                                         |
| 208 |    782.290326 |    541.858853 | xgirouxb                                                                                                                                                              |
| 209 |     30.769211 |    718.177873 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 210 |    504.974552 |    413.757818 | Chris huh                                                                                                                                                             |
| 211 |    883.861203 |    636.419356 | Matt Crook                                                                                                                                                            |
| 212 |    726.515440 |    448.908669 | Birgit Lang                                                                                                                                                           |
| 213 |    375.342879 |     52.719344 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 214 |    931.672434 |    583.872938 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 215 |    860.535587 |    656.856469 | Lukasiniho                                                                                                                                                            |
| 216 |    763.361944 |    353.731581 | Yan Wong                                                                                                                                                              |
| 217 |    179.818013 |    167.539707 | Michelle Site                                                                                                                                                         |
| 218 |    280.333570 |    465.933884 | Lukasiniho                                                                                                                                                            |
| 219 |     33.809170 |    193.405364 | Zimices                                                                                                                                                               |
| 220 |    214.022349 |    784.749895 | Michelle Site                                                                                                                                                         |
| 221 |    470.039272 |    194.257385 | Sarah Werning                                                                                                                                                         |
| 222 |    231.249106 |     92.896065 | Beth Reinke                                                                                                                                                           |
| 223 |    437.047968 |    192.635522 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 224 |    873.200417 |    419.457902 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 225 |    205.798914 |    561.915295 | Caleb M. Brown                                                                                                                                                        |
| 226 |    303.866695 |     15.402331 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 227 |    185.442754 |    321.036335 | T. Michael Keesey                                                                                                                                                     |
| 228 |    304.602104 |    692.449065 | Matt Crook                                                                                                                                                            |
| 229 |    134.470529 |    181.278858 | Tasman Dixon                                                                                                                                                          |
| 230 |    947.360197 |    448.924277 | Nick Schooler                                                                                                                                                         |
| 231 |    814.372894 |    220.912648 | zoosnow                                                                                                                                                               |
| 232 |    959.897197 |    443.036718 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 233 |    635.854405 |    716.444532 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 234 |    271.512679 |    201.057843 | Peileppe                                                                                                                                                              |
| 235 |    128.014563 |    535.456076 | Matt Crook                                                                                                                                                            |
| 236 |    742.625963 |     42.507076 | SauropodomorphMonarch                                                                                                                                                 |
| 237 |    756.695437 |    694.015302 | Kai R. Caspar                                                                                                                                                         |
| 238 |    354.002785 |    277.503081 | NA                                                                                                                                                                    |
| 239 |    809.098210 |    257.219394 | Matt Crook                                                                                                                                                            |
| 240 |    690.603069 |     93.651149 | T. Michael Keesey                                                                                                                                                     |
| 241 |    207.558769 |    796.894938 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 242 |    719.677850 |    567.231344 | Zimices                                                                                                                                                               |
| 243 |    247.917088 |    623.370088 | Sean McCann                                                                                                                                                           |
| 244 |      7.601834 |    441.751483 | Margot Michaud                                                                                                                                                        |
| 245 |    851.918513 |    480.620450 | Sarah Werning                                                                                                                                                         |
| 246 |    347.728816 |    299.020332 | Zimices                                                                                                                                                               |
| 247 |    328.674022 |    409.009976 | T. Michael Keesey                                                                                                                                                     |
| 248 |    375.339822 |    498.968076 | Chris huh                                                                                                                                                             |
| 249 |    523.398034 |    752.722492 | Katie S. Collins                                                                                                                                                      |
| 250 |    393.668471 |    198.560957 | Jaime Headden                                                                                                                                                         |
| 251 |    511.783889 |    181.721727 | Auckland Museum                                                                                                                                                       |
| 252 |     32.828001 |    181.716446 | Tasman Dixon                                                                                                                                                          |
| 253 |    158.241441 |     22.228234 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 254 |    288.719930 |    250.143276 | NA                                                                                                                                                                    |
| 255 |     80.952614 |    787.901576 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 256 |    665.598938 |    562.074050 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 257 |    455.579404 |    355.016136 | Caleb M. Brown                                                                                                                                                        |
| 258 |    640.796673 |    341.122365 | Julia B McHugh                                                                                                                                                        |
| 259 |    460.923185 |    221.211288 | Margot Michaud                                                                                                                                                        |
| 260 |    728.424962 |    672.577391 | Michael Scroggie                                                                                                                                                      |
| 261 |    304.950675 |    314.810023 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 262 |    654.914963 |    359.779647 | Steven Traver                                                                                                                                                         |
| 263 |    535.152888 |    693.220738 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 264 |    429.928448 |    487.192874 | Dean Schnabel                                                                                                                                                         |
| 265 |    589.320388 |    364.224080 | Zimices                                                                                                                                                               |
| 266 |    955.192064 |    437.091564 | Daniel Stadtmauer                                                                                                                                                     |
| 267 |    769.074143 |    661.829548 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 268 |    207.091894 |    627.857250 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 269 |    866.731238 |    772.513767 | Lukasiniho                                                                                                                                                            |
| 270 |     17.457769 |    187.285458 | Steven Traver                                                                                                                                                         |
| 271 |    281.963043 |    359.289614 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 272 |    965.978361 |    733.519811 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 273 |    870.239889 |    565.477837 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 274 |    476.080014 |    420.476565 | Matt Crook                                                                                                                                                            |
| 275 |    394.236551 |    473.419111 | Dean Schnabel                                                                                                                                                         |
| 276 |    221.263094 |     52.863902 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 277 |    268.421852 |    319.526834 | Felix Vaux                                                                                                                                                            |
| 278 |    464.762933 |    204.897273 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 279 |     64.103522 |    182.428934 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 280 |    624.530924 |    275.986363 | Zimices                                                                                                                                                               |
| 281 |    851.205171 |    465.475892 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 282 |    254.069409 |    771.193480 | Ferran Sayol                                                                                                                                                          |
| 283 |    786.196974 |    524.086686 | Matt Crook                                                                                                                                                            |
| 284 |    679.271859 |    414.362053 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 285 |    874.561701 |    639.531704 | Margot Michaud                                                                                                                                                        |
| 286 |    304.740416 |    520.442234 | Matt Crook                                                                                                                                                            |
| 287 |    246.081146 |     77.205029 | Matus Valach                                                                                                                                                          |
| 288 |    167.994998 |    297.014367 | L. Shyamal                                                                                                                                                            |
| 289 |     82.041583 |     33.779004 | Ferran Sayol                                                                                                                                                          |
| 290 |    908.651033 |    724.989960 | Ferran Sayol                                                                                                                                                          |
| 291 |    485.988356 |    151.272360 | NA                                                                                                                                                                    |
| 292 |    116.700900 |    120.878226 | Zimices                                                                                                                                                               |
| 293 |    675.606626 |    327.893028 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 294 |    509.393445 |    358.022508 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 295 |    308.489452 |    408.106834 | Kamil S. Jaron                                                                                                                                                        |
| 296 |    661.901781 |    389.507533 | Myriam\_Ramirez                                                                                                                                                       |
| 297 |    492.318717 |    347.895339 | Gareth Monger                                                                                                                                                         |
| 298 |    732.439694 |    186.125410 | Chris huh                                                                                                                                                             |
| 299 |    277.889756 |    186.074186 | Dave Angelini                                                                                                                                                         |
| 300 |    612.070597 |    404.304259 | T. Michael Keesey                                                                                                                                                     |
| 301 |    496.382570 |     66.138244 | Chris huh                                                                                                                                                             |
| 302 |    850.667103 |    169.613041 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 303 |    524.730401 |    479.956928 | Renata F. Martins                                                                                                                                                     |
| 304 |    857.490099 |    392.350358 | NA                                                                                                                                                                    |
| 305 |    655.499758 |     50.731266 | Margot Michaud                                                                                                                                                        |
| 306 |    631.580715 |    503.843517 | Marmelad                                                                                                                                                              |
| 307 |    401.250804 |    672.117006 | Gareth Monger                                                                                                                                                         |
| 308 |    378.189764 |    671.263306 | Lafage                                                                                                                                                                |
| 309 |    317.037507 |    392.215635 | Alex Slavenko                                                                                                                                                         |
| 310 |    905.395421 |    600.258146 | Matt Crook                                                                                                                                                            |
| 311 |    193.498432 |    509.499568 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 312 |    641.760180 |    712.113240 | Margot Michaud                                                                                                                                                        |
| 313 |    774.828628 |    503.123065 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 314 |    128.559270 |     21.159450 | Xavier Giroux-Bougard                                                                                                                                                 |
| 315 |    889.098002 |    661.222432 | Margot Michaud                                                                                                                                                        |
| 316 |    674.463197 |    207.171951 | Steven Traver                                                                                                                                                         |
| 317 |    273.564511 |    349.306680 | Margot Michaud                                                                                                                                                        |
| 318 |    118.497390 |     50.258015 | Jagged Fang Designs                                                                                                                                                   |
| 319 |    891.325327 |    224.421544 | Tasman Dixon                                                                                                                                                          |
| 320 |    930.795385 |     80.887522 | Steven Traver                                                                                                                                                         |
| 321 |    583.527710 |    154.768387 | NA                                                                                                                                                                    |
| 322 |    226.769400 |    189.354689 | Ferran Sayol                                                                                                                                                          |
| 323 |    466.960867 |    308.047085 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 324 |     95.289326 |    506.860497 | NA                                                                                                                                                                    |
| 325 |    714.270834 |    634.392655 | Zimices                                                                                                                                                               |
| 326 |    372.345062 |    466.098547 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 327 |    914.110328 |     79.844389 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 328 |    932.846816 |    598.068461 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 329 |    228.234309 |    725.811154 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 330 |    973.023813 |    578.824323 | Sharon Wegner-Larsen                                                                                                                                                  |
| 331 |    144.535428 |    197.484767 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 332 |    130.100865 |    450.032600 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 333 |    519.523368 |    295.401438 | NA                                                                                                                                                                    |
| 334 |    155.334061 |    154.664770 | Zimices                                                                                                                                                               |
| 335 |    561.886836 |    793.418621 | NA                                                                                                                                                                    |
| 336 |     70.556524 |    292.271203 | Margot Michaud                                                                                                                                                        |
| 337 |    204.590083 |    787.415498 | Steven Traver                                                                                                                                                         |
| 338 |    280.725159 |    645.084776 | T. Michael Keesey                                                                                                                                                     |
| 339 |    833.193438 |    357.659313 | Scott Hartman                                                                                                                                                         |
| 340 |   1014.777394 |    260.652687 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 341 |    210.417188 |    776.681753 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 342 |    972.537062 |    443.512895 | Margot Michaud                                                                                                                                                        |
| 343 |    411.588346 |     21.597455 | Rebecca Groom                                                                                                                                                         |
| 344 |    237.646892 |    304.791038 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 345 |      7.827645 |    223.565069 | Kamil S. Jaron                                                                                                                                                        |
| 346 |    194.077331 |    792.374963 | Zimices                                                                                                                                                               |
| 347 |    416.631935 |    711.079206 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 348 |    924.318798 |    588.500915 | Katie S. Collins                                                                                                                                                      |
| 349 |    254.025257 |    235.422537 | Chris A. Hamilton                                                                                                                                                     |
| 350 |    140.656992 |     36.330779 | Manabu Sakamoto                                                                                                                                                       |
| 351 |    301.683892 |    644.369134 | Christoph Schomburg                                                                                                                                                   |
| 352 |    396.408417 |    186.895546 | Ferran Sayol                                                                                                                                                          |
| 353 |    473.873673 |    347.110667 | Scott Hartman                                                                                                                                                         |
| 354 |    334.197496 |     72.926126 | Matt Crook                                                                                                                                                            |
| 355 |    153.744476 |    276.460973 | Matt Crook                                                                                                                                                            |
| 356 |    801.210582 |    380.489292 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 357 |     33.566067 |    641.806474 | Chris huh                                                                                                                                                             |
| 358 |    523.038515 |    739.633820 | Cesar Julian                                                                                                                                                          |
| 359 |    191.784197 |    649.615812 | Zimices                                                                                                                                                               |
| 360 |    837.657750 |    147.947655 | Emma Kissling                                                                                                                                                         |
| 361 |    180.378501 |     21.424771 | Gareth Monger                                                                                                                                                         |
| 362 |    167.379725 |    153.323995 | Margot Michaud                                                                                                                                                        |
| 363 |    237.285827 |     13.364480 | Zimices                                                                                                                                                               |
| 364 |    947.956426 |    610.272645 | Andrew A. Farke                                                                                                                                                       |
| 365 |    526.940103 |    335.835595 | Gareth Monger                                                                                                                                                         |
| 366 |    537.904554 |    188.601605 | Beth Reinke                                                                                                                                                           |
| 367 |    427.590815 |    206.870075 | Julio Garza                                                                                                                                                           |
| 368 |    280.539154 |    640.210819 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 369 |    738.436560 |    429.236334 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 370 |     53.096154 |    388.160188 | Zimices                                                                                                                                                               |
| 371 |    862.584914 |    238.588790 | Mattia Menchetti                                                                                                                                                      |
| 372 |    993.229031 |    213.610055 | Margot Michaud                                                                                                                                                        |
| 373 |    621.825589 |    364.417076 | Sarah Werning                                                                                                                                                         |
| 374 |    992.009586 |    625.714598 | Dean Schnabel                                                                                                                                                         |
| 375 |    858.911795 |    170.332230 | Matt Dempsey                                                                                                                                                          |
| 376 |    991.314755 |    426.887691 | Michael Scroggie                                                                                                                                                      |
| 377 |    106.110800 |    447.755623 | Jagged Fang Designs                                                                                                                                                   |
| 378 |    923.793352 |    411.464424 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 379 |     55.789958 |    705.652556 | Margot Michaud                                                                                                                                                        |
| 380 |    292.419170 |    573.558706 | Raven Amos                                                                                                                                                            |
| 381 |    771.134771 |     45.067984 | Michael P. Taylor                                                                                                                                                     |
| 382 |     67.594249 |    525.155723 | Zimices                                                                                                                                                               |
| 383 |    170.097703 |    203.968643 | Zimices                                                                                                                                                               |
| 384 |     52.720837 |    448.448188 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 385 |    780.164003 |    566.067920 | Chris huh                                                                                                                                                             |
| 386 |      9.406333 |    337.436057 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 387 |    223.879020 |    209.754296 | Scott Hartman                                                                                                                                                         |
| 388 |    178.021170 |    247.078769 | FunkMonk                                                                                                                                                              |
| 389 |    276.394861 |    272.276889 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
| 390 |     96.452918 |    790.158232 | Matt Crook                                                                                                                                                            |
| 391 |    796.600741 |    661.451456 | Tasman Dixon                                                                                                                                                          |
| 392 |     24.032269 |    271.088517 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 393 |    791.053804 |     72.805754 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 394 |    433.285415 |     46.222427 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 395 |    275.915355 |    452.920318 | Margot Michaud                                                                                                                                                        |
| 396 |    919.151425 |    499.136538 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 397 |     78.933118 |    749.006455 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 398 |    561.138565 |    305.116694 | Birgit Lang                                                                                                                                                           |
| 399 |     95.753193 |     16.133161 | Matthew E. Clapham                                                                                                                                                    |
| 400 |    316.123455 |    320.455290 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 401 |    367.156480 |     90.147246 | Michelle Site                                                                                                                                                         |
| 402 |    663.669342 |    449.428395 | Ferran Sayol                                                                                                                                                          |
| 403 |      8.472320 |    213.887537 | Matt Crook                                                                                                                                                            |
| 404 |     74.588492 |    658.359092 | Jonathan Wells                                                                                                                                                        |
| 405 |    477.291556 |    301.188235 | Scott Hartman                                                                                                                                                         |
| 406 |    571.362404 |    391.478242 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 407 |    225.987791 |    309.646350 | Maija Karala                                                                                                                                                          |
| 408 |    571.343443 |    487.737586 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 409 |    700.646592 |    681.793982 | Manabu Bessho-Uehara                                                                                                                                                  |
| 410 |    637.274415 |    494.993691 | Gareth Monger                                                                                                                                                         |
| 411 |    156.242280 |    179.635071 | (after Spotila 2004)                                                                                                                                                  |
| 412 |    799.897846 |    368.622739 | Stuart Humphries                                                                                                                                                      |
| 413 |     18.579366 |    341.084061 | Jagged Fang Designs                                                                                                                                                   |
| 414 |    722.947235 |    665.112783 | Jagged Fang Designs                                                                                                                                                   |
| 415 |    171.400871 |    485.586088 | Margot Michaud                                                                                                                                                        |
| 416 |    226.886493 |    682.880679 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 417 |     63.049380 |    124.117031 | Collin Gross                                                                                                                                                          |
| 418 |    410.419877 |    788.662323 | M Kolmann                                                                                                                                                             |
| 419 |    763.110790 |    521.342214 | NA                                                                                                                                                                    |
| 420 |    430.782687 |    729.853926 | Margot Michaud                                                                                                                                                        |
| 421 |    184.644644 |    116.113162 | Matus Valach                                                                                                                                                          |
| 422 |    390.098229 |    692.128358 | CNZdenek                                                                                                                                                              |
| 423 |    400.386917 |    656.540072 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 424 |    440.265529 |    237.893889 | Zimices                                                                                                                                                               |
| 425 |    164.847205 |     33.139281 | Milton Tan                                                                                                                                                            |
| 426 |    895.613644 |    197.125178 | Maxime Dahirel                                                                                                                                                        |
| 427 |     93.757799 |    402.556984 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 428 |    330.261323 |    623.622198 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 429 |    704.691089 |    709.318364 | Mattia Menchetti                                                                                                                                                      |
| 430 |    610.265612 |     66.651077 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 431 |    982.203338 |    293.952257 | Scott Hartman                                                                                                                                                         |
| 432 |    399.974679 |    730.636603 | Davidson Sodré                                                                                                                                                        |
| 433 |   1013.084786 |    358.287527 | Terpsichores                                                                                                                                                          |
| 434 |    663.139939 |     85.364709 | Zimices                                                                                                                                                               |
| 435 |    447.850002 |    436.664806 | Bryan Carstens                                                                                                                                                        |
| 436 |    710.751283 |    786.646030 | Katie S. Collins                                                                                                                                                      |
| 437 |     38.364523 |    281.786549 | Sean McCann                                                                                                                                                           |
| 438 |    402.162874 |    763.960205 | B Kimmel                                                                                                                                                              |
| 439 |    830.698067 |    267.687452 | Ingo Braasch                                                                                                                                                          |
| 440 |    829.805590 |    392.259079 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 441 |   1007.250972 |    176.650078 | Mike Hanson                                                                                                                                                           |
| 442 |    665.415416 |    124.042764 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 443 |    789.388912 |    392.393720 | Matt Crook                                                                                                                                                            |
| 444 |    391.363937 |    664.088131 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 445 |    705.454915 |    616.889969 | Zimices                                                                                                                                                               |
| 446 |    883.267076 |    400.616290 | Michelle Site                                                                                                                                                         |
| 447 |    934.879565 |    478.403326 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 448 |    979.319389 |    570.687850 | NA                                                                                                                                                                    |
| 449 |    506.429465 |     10.000557 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 450 |     35.952438 |    702.972856 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 451 |    114.348256 |    305.499804 | Harold N Eyster                                                                                                                                                       |
| 452 |    258.681275 |    194.371412 | NA                                                                                                                                                                    |
| 453 |     34.764474 |    152.102530 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 454 |    223.408700 |    764.057618 | NA                                                                                                                                                                    |
| 455 |    911.975973 |    270.788995 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 456 |    340.847331 |    131.730239 | Alex Slavenko                                                                                                                                                         |
| 457 |    822.487775 |    131.458797 | Beth Reinke                                                                                                                                                           |
| 458 |    870.595692 |    794.808244 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 459 |    478.583032 |    673.163173 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 460 |    220.628319 |    428.298182 | L. Shyamal                                                                                                                                                            |
| 461 |     62.513319 |    637.905924 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 462 |    923.307294 |    384.240942 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 463 |    854.967897 |    730.721644 | Harold N Eyster                                                                                                                                                       |
| 464 |    854.546738 |    456.112215 | Nobu Tamura                                                                                                                                                           |
| 465 |    141.551493 |    750.670247 | François Michonneau                                                                                                                                                   |
| 466 |    203.868007 |    177.085481 | Margot Michaud                                                                                                                                                        |
| 467 |    623.123046 |     27.956504 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 468 |    255.926108 |    271.979695 | Melissa Broussard                                                                                                                                                     |
| 469 |     96.002390 |    695.618982 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 470 |    636.148517 |    357.483828 | Scott Hartman                                                                                                                                                         |
| 471 |    750.264080 |    545.320671 | Stuart Humphries                                                                                                                                                      |
| 472 |    608.517860 |    756.304989 | Rebecca Groom                                                                                                                                                         |
| 473 |    679.485263 |    544.645579 | NA                                                                                                                                                                    |
| 474 |     41.592881 |    696.678281 | New York Zoological Society                                                                                                                                           |
| 475 |    260.074652 |    378.389245 | Mattia Menchetti                                                                                                                                                      |
| 476 |     90.556066 |    554.600390 | Tracy A. Heath                                                                                                                                                        |
| 477 |     96.106840 |    149.387039 | Zimices                                                                                                                                                               |
| 478 |    436.954429 |    180.397712 | Matt Crook                                                                                                                                                            |
| 479 |   1000.421495 |    737.152579 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 480 |    878.223352 |    651.552225 | Zimices                                                                                                                                                               |
| 481 |    185.246389 |     29.080874 | T. Michael Keesey                                                                                                                                                     |
| 482 |    896.974981 |    508.864751 | NA                                                                                                                                                                    |
| 483 |    377.931246 |    744.327575 | Noah Schlottman                                                                                                                                                       |
| 484 |    940.447171 |    510.335579 | Roberto Díaz Sibaja                                                                                                                                                   |
| 485 |    203.410733 |    273.152013 | Melissa Broussard                                                                                                                                                     |
| 486 |    694.794814 |    182.238420 | Matt Crook                                                                                                                                                            |
| 487 |    531.029244 |     99.180405 | Tyler McCraney                                                                                                                                                        |
| 488 |    287.091979 |    325.642475 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 489 |    195.881213 |    281.795238 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 490 |    976.959453 |    222.375559 | Maija Karala                                                                                                                                                          |
| 491 |   1007.546298 |    451.752651 | Juan Carlos Jerí                                                                                                                                                      |
| 492 |    247.757099 |     48.845455 | Zimices                                                                                                                                                               |
| 493 |    426.716380 |    776.518008 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 494 |    170.039251 |    554.153127 | Tasman Dixon                                                                                                                                                          |
| 495 |    713.190756 |    355.773135 | T. Michael Keesey                                                                                                                                                     |
| 496 |    486.333000 |    412.251970 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 497 |     42.555459 |     90.569739 | B. Duygu Özpolat                                                                                                                                                      |
| 498 |    901.752536 |    411.628485 | Steven Traver                                                                                                                                                         |
| 499 |    627.961271 |    497.603261 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 500 |    413.295509 |    753.398407 | Julien Louys                                                                                                                                                          |
| 501 |      9.851396 |    480.499958 | Rebecca Groom                                                                                                                                                         |
| 502 |    211.544922 |    321.324364 | Matt Celeskey                                                                                                                                                         |
| 503 |    584.308598 |    228.605838 | Jake Warner                                                                                                                                                           |
| 504 |    152.430718 |    795.327044 | Collin Gross                                                                                                                                                          |
| 505 |    654.501407 |    367.735572 | Roberto Díaz Sibaja                                                                                                                                                   |
| 506 |    794.896032 |    465.341299 | Anthony Caravaggi                                                                                                                                                     |
| 507 |    339.247038 |    288.336573 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 508 |    195.163203 |     43.849643 | CNZdenek                                                                                                                                                              |
| 509 |    893.401614 |     68.137830 | Crystal Maier                                                                                                                                                         |
| 510 |    482.864351 |    198.122869 | Beth Reinke                                                                                                                                                           |
| 511 |    783.716799 |    157.617356 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 512 |     10.395241 |    635.565919 | Collin Gross                                                                                                                                                          |
| 513 |    534.815320 |    230.980861 | V. Deepak                                                                                                                                                             |
| 514 |    694.660802 |    418.650775 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 515 |    607.647001 |    452.317091 | Andrew A. Farke                                                                                                                                                       |
| 516 |    177.150463 |     30.652580 | T. Michael Keesey                                                                                                                                                     |
| 517 |   1005.115801 |    399.684745 | NA                                                                                                                                                                    |
| 518 |    887.174902 |    773.090809 | Kent Elson Sorgon                                                                                                                                                     |
| 519 |      8.201256 |    150.976724 | Mathilde Cordellier                                                                                                                                                   |
| 520 |    102.811127 |    229.232706 | Tyler Greenfield                                                                                                                                                      |
| 521 |    908.569433 |    711.139460 | Milton Tan                                                                                                                                                            |
| 522 |    869.607524 |    117.812523 | Matt Crook                                                                                                                                                            |
| 523 |     22.615034 |    664.697236 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 524 |    130.242861 |     80.965616 | Iain Reid                                                                                                                                                             |
| 525 |    115.644390 |    792.650199 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 526 |    405.758705 |     91.231950 | Frank Förster                                                                                                                                                         |
| 527 |    742.586350 |    644.158276 | Tasman Dixon                                                                                                                                                          |
| 528 |     84.991437 |    688.212256 | Maija Karala                                                                                                                                                          |
| 529 |     10.157908 |    262.252092 | Iain Reid                                                                                                                                                             |
| 530 |    851.284899 |    581.272068 | Noah Schlottman                                                                                                                                                       |
| 531 |    241.878464 |    771.456321 | T. Michael Keesey                                                                                                                                                     |
| 532 |    145.281069 |     88.231822 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 533 |    757.315818 |    480.773129 | Sarah Werning                                                                                                                                                         |
| 534 |    721.457862 |     38.527850 | Zimices                                                                                                                                                               |
| 535 |    450.615612 |    489.728264 | Nobu Tamura                                                                                                                                                           |
| 536 |     91.787121 |    693.619019 | Armin Reindl                                                                                                                                                          |
| 537 |    633.917668 |    510.687250 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 538 |     24.866713 |    681.757591 | Jagged Fang Designs                                                                                                                                                   |
| 539 |     14.589307 |      7.584518 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 540 |    483.783583 |    293.169380 | Steven Traver                                                                                                                                                         |
| 541 |    497.152104 |    260.680656 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 542 |    220.203407 |    794.927970 | Tracy A. Heath                                                                                                                                                        |
| 543 |    412.275583 |    385.627859 | Gareth Monger                                                                                                                                                         |
| 544 |    574.123423 |    756.927500 | Zimices                                                                                                                                                               |
| 545 |    163.523117 |     45.498264 | Tauana J. Cunha                                                                                                                                                       |
| 546 |   1009.155201 |    312.006025 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 547 |    885.282538 |    124.688760 | T. Michael Keesey                                                                                                                                                     |
| 548 |    379.471363 |     77.657251 | Steven Traver                                                                                                                                                         |
| 549 |    650.818514 |    535.317950 | Margot Michaud                                                                                                                                                        |
| 550 |    858.952670 |    222.072267 | Matt Crook                                                                                                                                                            |
| 551 |    480.156399 |    750.929816 | Gareth Monger                                                                                                                                                         |
| 552 |    711.804389 |    166.762905 | Zimices                                                                                                                                                               |
| 553 |    198.232850 |    660.084574 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 554 |    677.774504 |    394.979852 | Birgit Lang                                                                                                                                                           |
| 555 |    849.136299 |    356.842523 | Kai R. Caspar                                                                                                                                                         |
| 556 |    901.308251 |    384.896568 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 557 |    305.004905 |    227.136993 | Ferran Sayol                                                                                                                                                          |
| 558 |    364.921681 |    636.802520 | Matt Crook                                                                                                                                                            |
| 559 |    674.917110 |    178.149687 | Milton Tan                                                                                                                                                            |
| 560 |    216.059704 |    263.126113 | Natasha Vitek                                                                                                                                                         |
| 561 |    531.673874 |    389.752431 | Harold N Eyster                                                                                                                                                       |
| 562 |     64.720444 |    541.619464 | Birgit Lang                                                                                                                                                           |
| 563 |    934.053098 |    211.479703 | Matt Crook                                                                                                                                                            |
| 564 |    607.790780 |     42.379123 | Matt Crook                                                                                                                                                            |
| 565 |     10.919347 |     90.367661 | Carlos Cano-Barbacil                                                                                                                                                  |
| 566 |    112.977671 |    454.853973 | Gareth Monger                                                                                                                                                         |
| 567 |    267.131909 |      2.059509 | Julio Garza                                                                                                                                                           |
| 568 |      3.043458 |    572.557295 | T. Michael Keesey                                                                                                                                                     |
| 569 |    683.407554 |    526.187187 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 570 |    124.491676 |    787.592884 | Steven Traver                                                                                                                                                         |
| 571 |    614.032311 |    435.840774 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 572 |    214.206088 |    624.701488 | Noah Schlottman                                                                                                                                                       |
| 573 |     73.069348 |    181.378276 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 574 |    110.842810 |    515.449702 | Steven Traver                                                                                                                                                         |
| 575 |    627.924201 |    759.430716 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 576 |    253.154362 |    298.369189 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 577 |    766.157052 |      4.281542 | Matt Crook                                                                                                                                                            |
| 578 |    433.405367 |    225.648050 | NA                                                                                                                                                                    |
| 579 |    128.278036 |    168.484730 | Roberto Díaz Sibaja                                                                                                                                                   |
| 580 |     26.425041 |    655.248723 | NA                                                                                                                                                                    |
| 581 |    323.582022 |    579.381692 | Beth Reinke                                                                                                                                                           |
| 582 |    943.435492 |     76.060433 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 583 |    122.105834 |    100.093687 | NA                                                                                                                                                                    |
| 584 |    657.447368 |    759.789799 | NA                                                                                                                                                                    |
| 585 |    738.931002 |    527.420617 | Chris huh                                                                                                                                                             |
| 586 |    915.686768 |    389.545237 | Ludwik Gasiorowski                                                                                                                                                    |
| 587 |    688.169112 |    352.908711 | Rebecca Groom                                                                                                                                                         |
| 588 |    298.560359 |    577.299889 | Katie S. Collins                                                                                                                                                      |
| 589 |    269.576811 |     71.971265 | Scott Reid                                                                                                                                                            |
| 590 |    720.777850 |    163.223357 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 591 |    434.847484 |      3.209695 | Chris huh                                                                                                                                                             |
| 592 |    449.950338 |    245.788646 | Gareth Monger                                                                                                                                                         |
| 593 |    675.861095 |     92.883899 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 594 |    368.110173 |    305.663425 | Melissa Broussard                                                                                                                                                     |
| 595 |    503.987842 |    445.466342 | T. Michael Keesey                                                                                                                                                     |
| 596 |    819.541627 |    558.109395 | Noah Schlottman                                                                                                                                                       |
| 597 |     44.683530 |    552.549836 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 598 |    221.763665 |    662.137171 | Chloé Schmidt                                                                                                                                                         |
| 599 |     52.533927 |     47.320833 | Margot Michaud                                                                                                                                                        |
| 600 |     95.478227 |    481.661591 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 601 |    428.987856 |     27.929381 | Ferran Sayol                                                                                                                                                          |
| 602 |    847.812844 |    223.779608 | Danielle Alba                                                                                                                                                         |
| 603 |    553.114589 |     97.698777 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 604 |    662.203077 |    546.544550 | NA                                                                                                                                                                    |
| 605 |    407.969175 |    494.051232 | Zimices                                                                                                                                                               |
| 606 |    205.890528 |    211.916176 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 607 |    535.089367 |    409.122335 | FunkMonk                                                                                                                                                              |
| 608 |    505.414694 |    231.958258 | Jagged Fang Designs                                                                                                                                                   |
| 609 |    709.230975 |    729.502960 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 610 |    528.343962 |    350.502213 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 611 |    527.077403 |    329.858372 | Alex Slavenko                                                                                                                                                         |
| 612 |    868.796384 |    439.180122 | Fernando Carezzano                                                                                                                                                    |
| 613 |    397.713126 |    477.732948 | David Orr                                                                                                                                                             |
| 614 |    386.188061 |    681.159541 | Steven Traver                                                                                                                                                         |
| 615 |   1002.720645 |    423.319166 | Ferran Sayol                                                                                                                                                          |
| 616 |    738.370390 |     23.661798 | L. Shyamal                                                                                                                                                            |
| 617 |    327.743509 |    587.753398 | Lauren Anderson                                                                                                                                                       |
| 618 |     91.605324 |    648.159788 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 619 |    967.768197 |    337.241825 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 620 |    969.964404 |    610.621242 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 621 |    724.516595 |    511.878081 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 622 |    540.007623 |    663.461541 | Chris huh                                                                                                                                                             |
| 623 |    215.562812 |    309.088238 | Collin Gross                                                                                                                                                          |
| 624 |    566.444297 |     88.407865 | Tasman Dixon                                                                                                                                                          |
| 625 |    635.312401 |    405.358368 | Margot Michaud                                                                                                                                                        |
| 626 |    302.537918 |    798.032315 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 627 |     78.858811 |    532.756909 | Beth Reinke                                                                                                                                                           |
| 628 |    804.170375 |     41.477967 | Tasman Dixon                                                                                                                                                          |
| 629 |    728.258079 |     49.274234 | Steven Traver                                                                                                                                                         |
| 630 |    416.231890 |     73.651316 | Gareth Monger                                                                                                                                                         |
| 631 |     88.767440 |    679.805584 | Tauana J. Cunha                                                                                                                                                       |
| 632 |    305.268081 |    650.152706 | Zimices                                                                                                                                                               |
| 633 |    853.531001 |    786.191521 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 634 |    805.133460 |    561.459270 | Jagged Fang Designs                                                                                                                                                   |
| 635 |    775.801548 |    276.135936 | Zimices                                                                                                                                                               |
| 636 |    671.872818 |    350.894385 | Gareth Monger                                                                                                                                                         |
| 637 |    946.796019 |    288.521055 | Margot Michaud                                                                                                                                                        |
| 638 |    600.448703 |    493.400338 | Sarah Werning                                                                                                                                                         |
| 639 |    529.030666 |    437.135555 | Michele M Tobias                                                                                                                                                      |
| 640 |    693.554916 |    344.247023 | Matt Crook                                                                                                                                                            |
| 641 |    618.422122 |    405.997384 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
| 642 |    662.478887 |     58.595119 | Margot Michaud                                                                                                                                                        |
| 643 |    244.670259 |    353.889052 | NA                                                                                                                                                                    |
| 644 |    965.119444 |    710.065899 | NA                                                                                                                                                                    |
| 645 |    812.461571 |    144.440368 | Matt Crook                                                                                                                                                            |
| 646 |    621.897107 |    392.026012 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 647 |    749.509176 |    268.194729 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 648 |    481.227609 |    175.085735 | Zimices                                                                                                                                                               |
| 649 |    215.620998 |      8.132834 | David Orr                                                                                                                                                             |
| 650 |    990.359362 |    138.477491 | Zimices                                                                                                                                                               |
| 651 |    513.952669 |    398.446626 | NA                                                                                                                                                                    |
| 652 |    941.732092 |     87.873249 | Zimices                                                                                                                                                               |
| 653 |    253.854314 |    416.338261 | Matt Crook                                                                                                                                                            |
| 654 |    101.220342 |    179.941317 | Steven Traver                                                                                                                                                         |
| 655 |    420.987427 |    487.827262 | Dean Schnabel                                                                                                                                                         |
| 656 |    399.857883 |    276.429075 | Zimices                                                                                                                                                               |
| 657 |    579.845655 |    476.194547 | T. Michael Keesey                                                                                                                                                     |
| 658 |    735.290709 |    341.500687 | Scott Hartman                                                                                                                                                         |
| 659 |    504.275333 |    319.359784 | Zimices                                                                                                                                                               |
| 660 |    586.706616 |    761.864984 | Zimices                                                                                                                                                               |
| 661 |    597.522603 |    785.274656 | Margot Michaud                                                                                                                                                        |
| 662 |     62.183231 |    324.753329 | Chris huh                                                                                                                                                             |
| 663 |    445.620858 |    772.969691 | Matt Crook                                                                                                                                                            |
| 664 |    315.949023 |    681.939541 | L. Shyamal                                                                                                                                                            |
| 665 |    965.245499 |     88.022089 | Zimices                                                                                                                                                               |
| 666 |     35.388843 |    795.814474 | Gareth Monger                                                                                                                                                         |
| 667 |    268.309867 |    299.662876 | S.Martini                                                                                                                                                             |
| 668 |    954.727593 |     82.443477 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 669 |    492.928707 |    334.479740 | Matt Crook                                                                                                                                                            |
| 670 |    750.238728 |    374.936786 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 671 |    687.268052 |    122.880065 | Chris huh                                                                                                                                                             |
| 672 |    692.251376 |    143.925028 | Ferran Sayol                                                                                                                                                          |
| 673 |    704.583014 |    148.622304 | Margot Michaud                                                                                                                                                        |
| 674 |     65.400728 |     42.983209 | Matt Crook                                                                                                                                                            |
| 675 |    307.517121 |    495.834874 | Jagged Fang Designs                                                                                                                                                   |
| 676 |      3.508302 |    419.371723 | Chase Brownstein                                                                                                                                                      |
| 677 |    140.746708 |     81.886875 | Jon Hill                                                                                                                                                              |
| 678 |     76.167008 |    628.833441 | M Kolmann                                                                                                                                                             |
| 679 |    407.697410 |    630.073094 | Danielle Alba                                                                                                                                                         |
| 680 |    267.293606 |    580.650493 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 681 |    157.773728 |    193.125350 | NA                                                                                                                                                                    |
| 682 |    141.176121 |    134.874913 | T. Michael Keesey                                                                                                                                                     |
| 683 |    809.641753 |    394.351475 | Andrew A. Farke                                                                                                                                                       |
| 684 |     16.123081 |    224.885833 | Margot Michaud                                                                                                                                                        |
| 685 |    866.590658 |    132.034099 | Chris Jennings (Risiatto)                                                                                                                                             |
| 686 |     30.570013 |    694.822145 | Matt Crook                                                                                                                                                            |
| 687 |    763.046717 |    790.247037 | Zimices                                                                                                                                                               |
| 688 |    635.123820 |    349.281754 | Geoff Shaw                                                                                                                                                            |
| 689 |     87.639058 |    636.018285 | Zimices                                                                                                                                                               |
| 690 |    914.992911 |    425.426201 | Walter Vladimir                                                                                                                                                       |
| 691 |      2.818176 |    731.600317 | NA                                                                                                                                                                    |
| 692 |    287.525739 |    525.827821 | NA                                                                                                                                                                    |
| 693 |    504.238123 |    424.508452 | Matt Crook                                                                                                                                                            |
| 694 |    290.223624 |    404.202101 | Margot Michaud                                                                                                                                                        |
| 695 |    225.166149 |    324.432439 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    609.699905 |    692.611904 | Michelle Site                                                                                                                                                         |
| 697 |    499.807811 |    404.322129 | Zimices                                                                                                                                                               |
| 698 |    552.295141 |    782.490566 | Mathieu Basille                                                                                                                                                       |
| 699 |    902.435909 |     39.049779 | T. Michael Keesey                                                                                                                                                     |
| 700 |    838.004749 |    480.046651 | Julio Garza                                                                                                                                                           |
| 701 |    380.262448 |     41.055122 | NA                                                                                                                                                                    |
| 702 |    882.727402 |    583.220255 | Felix Vaux                                                                                                                                                            |
| 703 |    620.219736 |     64.608265 | Scott Hartman                                                                                                                                                         |
| 704 |    879.470428 |    168.628216 | Roberto Díaz Sibaja                                                                                                                                                   |
| 705 |    754.458604 |    680.507709 | Zimices / Julián Bayona                                                                                                                                               |
| 706 |    175.498966 |    472.393597 | Dean Schnabel                                                                                                                                                         |
| 707 |    909.997367 |    698.820230 | Matt Crook                                                                                                                                                            |
| 708 |    157.390769 |    520.935216 | NA                                                                                                                                                                    |
| 709 |    108.264100 |    211.763753 | Scott Hartman                                                                                                                                                         |
| 710 |    733.474318 |    366.062647 | Margot Michaud                                                                                                                                                        |
| 711 |    836.039356 |    440.807658 | Birgit Lang                                                                                                                                                           |
| 712 |    365.595185 |    260.239908 | Nick Schooler                                                                                                                                                         |
| 713 |    977.275334 |    452.838510 | V. Deepak                                                                                                                                                             |
| 714 |    394.611287 |    620.184699 | Zachary Quigley                                                                                                                                                       |
| 715 |    710.554708 |    216.896877 | Christoph Schomburg                                                                                                                                                   |
| 716 |    800.472985 |    143.393542 | Jon Hill                                                                                                                                                              |
| 717 |    150.975053 |    460.097638 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 718 |   1013.579113 |    521.171098 | Michelle Site                                                                                                                                                         |
| 719 |    702.868280 |    284.464943 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 720 |    241.540106 |    174.617631 | C. Camilo Julián-Caballero                                                                                                                                            |
| 721 |    464.398977 |    297.719967 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 722 |    710.922887 |    769.452026 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 723 |    312.152322 |    186.856932 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 724 |    226.661376 |     38.459155 | Zimices                                                                                                                                                               |
| 725 |    106.969216 |    647.328120 | NA                                                                                                                                                                    |
| 726 |    533.039594 |    706.229494 | T. Michael Keesey                                                                                                                                                     |
| 727 |    920.426329 |    699.990535 | Matt Crook                                                                                                                                                            |
| 728 |     14.108445 |    138.872605 | Sharon Wegner-Larsen                                                                                                                                                  |
| 729 |    783.397598 |    438.608777 | Scott Hartman                                                                                                                                                         |
| 730 |    800.245681 |    767.823537 | Juan Carlos Jerí                                                                                                                                                      |
| 731 |    774.865789 |    495.395598 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 732 |    631.375797 |    726.741512 | Dmitry Bogdanov                                                                                                                                                       |
| 733 |    193.131351 |    147.775488 | Roberto Díaz Sibaja                                                                                                                                                   |
| 734 |    670.378866 |    362.291022 | Ferran Sayol                                                                                                                                                          |
| 735 |     25.424631 |    461.913802 | NA                                                                                                                                                                    |
| 736 |    752.283389 |     11.692773 | T. Michael Keesey                                                                                                                                                     |
| 737 |    175.691500 |    531.535689 | Jagged Fang Designs                                                                                                                                                   |
| 738 |    769.905772 |    367.276607 | Birgit Lang                                                                                                                                                           |
| 739 |    875.660606 |     66.568665 | NA                                                                                                                                                                    |
| 740 |    830.589959 |    648.304816 | Xavier Giroux-Bougard                                                                                                                                                 |
| 741 |    120.321737 |    111.454283 | L. Shyamal                                                                                                                                                            |
| 742 |     62.830122 |    288.575730 | Melissa Ingala                                                                                                                                                        |
| 743 |   1012.977028 |    380.315983 | Matt Martyniuk                                                                                                                                                        |
| 744 |    491.553102 |    198.973124 | Milton Tan                                                                                                                                                            |
| 745 |    183.177709 |    258.265505 | Zimices                                                                                                                                                               |
| 746 |    784.606534 |    666.123345 | Margot Michaud                                                                                                                                                        |
| 747 |   1013.797706 |    697.341606 | Steven Traver                                                                                                                                                         |
| 748 |    469.466790 |    775.347864 | Margot Michaud                                                                                                                                                        |
| 749 |    725.373463 |    239.815722 | Maxime Dahirel                                                                                                                                                        |
| 750 |    288.606820 |    673.294009 | Peileppe                                                                                                                                                              |
| 751 |     63.536387 |    268.630838 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 752 |    862.875507 |    412.513675 | Pete Buchholz                                                                                                                                                         |
| 753 |    438.690360 |    792.639584 | Zimices                                                                                                                                                               |
| 754 |    289.898513 |    378.718731 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 755 |     99.876931 |      3.983765 | Jimmy Bernot                                                                                                                                                          |
| 756 |    872.380918 |    228.630416 | Kamil S. Jaron                                                                                                                                                        |
| 757 |    838.421363 |    284.778341 | Sean McCann                                                                                                                                                           |
| 758 |    275.747491 |    232.079828 | Lukasiniho                                                                                                                                                            |
| 759 |    243.634332 |    694.930247 | NA                                                                                                                                                                    |
| 760 |    336.370079 |    589.607170 | Trond R. Oskars                                                                                                                                                       |
| 761 |     60.716273 |    612.142062 | Christine Axon                                                                                                                                                        |
| 762 |    607.474812 |    135.035653 | Maija Karala                                                                                                                                                          |
| 763 |     90.530639 |    168.826124 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 764 |    416.571258 |    434.294124 | Ferran Sayol                                                                                                                                                          |
| 765 |    321.966395 |    177.634661 | Margot Michaud                                                                                                                                                        |
| 766 |     68.437955 |    195.926302 | NA                                                                                                                                                                    |
| 767 |    284.487721 |    370.231721 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 768 |    512.126868 |    290.855894 | Birgit Lang                                                                                                                                                           |
| 769 |    861.035516 |    215.059815 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 770 |    729.932048 |     30.697647 | Michelle Site                                                                                                                                                         |
| 771 |     89.576489 |    538.540201 | Maxime Dahirel                                                                                                                                                        |
| 772 |    451.897765 |     52.149210 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 773 |    544.646096 |    380.112083 | NA                                                                                                                                                                    |
| 774 |    186.978032 |    285.094908 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 775 |    256.759877 |    764.793205 | Jagged Fang Designs                                                                                                                                                   |
| 776 |    131.698798 |    147.560148 | NA                                                                                                                                                                    |
| 777 |    537.693962 |    396.132185 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 778 |    228.330417 |    700.253317 | Matt Crook                                                                                                                                                            |
| 779 |    735.469834 |    681.268022 | S.Martini                                                                                                                                                             |
| 780 |    917.997338 |    527.431604 | Chris huh                                                                                                                                                             |
| 781 |    255.130649 |    660.273697 | Melissa Broussard                                                                                                                                                     |
| 782 |    726.710146 |    488.571353 | NA                                                                                                                                                                    |
| 783 |    232.578422 |     78.544550 | Margot Michaud                                                                                                                                                        |
| 784 |    240.336199 |    220.554692 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 785 |     23.640610 |    159.962412 | Beth Reinke                                                                                                                                                           |
| 786 |    691.085054 |    317.361223 | Ferran Sayol                                                                                                                                                          |
| 787 |    836.652928 |    609.696367 | Rebecca Groom                                                                                                                                                         |
| 788 |    149.405652 |    479.145677 | Matt Crook                                                                                                                                                            |
| 789 |    470.066698 |    405.929711 | Inessa Voet                                                                                                                                                           |
| 790 |    729.902321 |    527.269758 | NA                                                                                                                                                                    |
| 791 |     37.790426 |    385.974256 | Dean Schnabel                                                                                                                                                         |
| 792 |    332.208224 |    581.847192 | Alexis Simon                                                                                                                                                          |
| 793 |    497.192608 |    707.323169 | Steven Traver                                                                                                                                                         |
| 794 |    472.725315 |    693.618578 | Kai R. Caspar                                                                                                                                                         |
| 795 |     74.547833 |    166.987340 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 796 |   1004.585007 |    299.715004 | Birgit Lang                                                                                                                                                           |
| 797 |    187.806560 |    709.198927 | Trond R. Oskars                                                                                                                                                       |
| 798 |    524.358196 |     90.328103 | Ferran Sayol                                                                                                                                                          |
| 799 |     32.834467 |    129.030687 | Kamil S. Jaron                                                                                                                                                        |
| 800 |    611.546436 |    455.528174 | Joanna Wolfe                                                                                                                                                          |
| 801 |    183.537677 |      7.350908 | Gareth Monger                                                                                                                                                         |
| 802 |     22.726015 |    784.902446 | Jagged Fang Designs                                                                                                                                                   |
| 803 |    476.426316 |    685.772719 | Noah Schlottman                                                                                                                                                       |
| 804 |    837.390463 |    396.220250 | Josefine Bohr Brask                                                                                                                                                   |
| 805 |    582.714428 |     34.103516 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 806 |    432.339244 |    358.859422 | Amanda Katzer                                                                                                                                                         |
| 807 |    816.087433 |    211.700708 | Gareth Monger                                                                                                                                                         |
| 808 |    925.615677 |    770.587765 | Margot Michaud                                                                                                                                                        |
| 809 |    836.418968 |     87.775739 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 810 |     19.333922 |    551.921150 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 811 |    589.203154 |     14.938593 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 812 |    771.983984 |    554.100307 | Renato Santos                                                                                                                                                         |
| 813 |    551.015202 |    478.242445 | Chris huh                                                                                                                                                             |
| 814 |    610.596258 |    460.355087 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 815 |     48.276483 |    619.425618 | Scott Hartman                                                                                                                                                         |
| 816 |    849.909009 |    559.531988 | Kai R. Caspar                                                                                                                                                         |
| 817 |    901.072937 |    765.209743 | Pete Buchholz                                                                                                                                                         |
| 818 |     36.796771 |    230.039012 | Zimices                                                                                                                                                               |
| 819 |    330.740478 |    559.399658 | NA                                                                                                                                                                    |
| 820 |    295.730636 |    446.939275 | Matt Crook                                                                                                                                                            |
| 821 |    376.656113 |    103.504265 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 822 |    976.461637 |    699.786717 | Steven Traver                                                                                                                                                         |
| 823 |    148.234395 |    465.403199 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 824 |    836.748286 |    235.402204 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 825 |     15.239246 |    112.450050 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 826 |    637.800328 |     87.182218 | Mathew Wedel                                                                                                                                                          |
| 827 |    617.579081 |    258.757920 | Birgit Lang                                                                                                                                                           |
| 828 |     16.349220 |     58.641857 | Christoph Schomburg                                                                                                                                                   |
| 829 |    586.883626 |    715.782152 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 830 |    635.623346 |     46.293397 | Matt Crook                                                                                                                                                            |
| 831 |    122.769762 |    296.149363 | Emily Willoughby                                                                                                                                                      |
| 832 |    365.632577 |     30.998648 | Kai R. Caspar                                                                                                                                                         |
| 833 |    275.479258 |    340.711908 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 834 |    954.190725 |    763.703187 | Matt Crook                                                                                                                                                            |
| 835 |    812.496079 |    606.210119 | Chris huh                                                                                                                                                             |
| 836 |      7.791091 |     18.931960 | Roberto Díaz Sibaja                                                                                                                                                   |
| 837 |    224.637031 |    710.736151 | Matt Crook                                                                                                                                                            |
| 838 |    659.323632 |    314.916464 | Matt Crook                                                                                                                                                            |
| 839 |    925.883677 |    718.953528 | Christoph Schomburg                                                                                                                                                   |
| 840 |    545.269041 |     87.081574 | Zimices                                                                                                                                                               |
| 841 |    119.707177 |    756.674308 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 842 |     90.874436 |    728.195372 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 843 |    920.974265 |    728.088219 | Scott Reid                                                                                                                                                            |
| 844 |    603.891793 |     52.724717 | NA                                                                                                                                                                    |
| 845 |     32.408938 |     46.830742 | Zimices                                                                                                                                                               |
| 846 |    445.122538 |    322.865688 | Katie S. Collins                                                                                                                                                      |
| 847 |    171.356662 |    246.807994 | Jagged Fang Designs                                                                                                                                                   |
| 848 |     15.254771 |    571.391928 | Katie S. Collins                                                                                                                                                      |
| 849 |    727.509630 |    691.401563 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 850 |    367.933976 |    784.069811 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 851 |    526.731934 |    268.711459 | Matt Crook                                                                                                                                                            |
| 852 |    496.113997 |    685.353280 | Gareth Monger                                                                                                                                                         |
| 853 |    999.171502 |    308.924492 | Dean Schnabel                                                                                                                                                         |
| 854 |    918.252103 |    551.787541 | NA                                                                                                                                                                    |
| 855 |    457.668313 |    192.269676 | Melissa Broussard                                                                                                                                                     |
| 856 |    723.613580 |    236.362321 | Melissa Broussard                                                                                                                                                     |
| 857 |    753.425635 |    706.432663 | Margot Michaud                                                                                                                                                        |
| 858 |    423.870254 |    473.065657 | NA                                                                                                                                                                    |
| 859 |   1001.643892 |    725.703421 | Margot Michaud                                                                                                                                                        |
| 860 |     31.681469 |    516.776316 | Lafage                                                                                                                                                                |
| 861 |    497.536465 |    285.831388 | Christoph Schomburg                                                                                                                                                   |
| 862 |     81.583855 |    511.285804 | Tracy A. Heath                                                                                                                                                        |
| 863 |    632.469880 |    168.862947 | Christoph Schomburg                                                                                                                                                   |
| 864 |    614.370457 |    195.803813 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 865 |    848.820922 |    152.114813 | Pete Buchholz                                                                                                                                                         |
| 866 |    417.379246 |    370.596540 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 867 |    609.902118 |    760.595098 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 868 |    203.892214 |    383.458605 | Matt Crook                                                                                                                                                            |
| 869 |    602.583965 |    484.510264 | Tauana J. Cunha                                                                                                                                                       |
| 870 |    255.101835 |    572.270652 | Christoph Schomburg                                                                                                                                                   |
| 871 |    296.280276 |    586.291545 | Noah Schlottman                                                                                                                                                       |
| 872 |    902.014864 |     92.329759 | Steven Traver                                                                                                                                                         |
| 873 |      7.256833 |     42.451880 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 874 |    709.589832 |    515.743952 | Jaime Headden                                                                                                                                                         |
| 875 |    362.028457 |     19.227198 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 876 |    998.397786 |    268.568930 | Nina Skinner                                                                                                                                                          |
| 877 |    221.607412 |    642.698376 | Jiekun He                                                                                                                                                             |
| 878 |   1002.023548 |    124.689802 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 879 |    616.903538 |     35.659882 | Terpsichores                                                                                                                                                          |
| 880 |    427.051874 |    166.814954 | Peileppe                                                                                                                                                              |
| 881 |     15.723653 |    655.935547 | S.Martini                                                                                                                                                             |
| 882 |    406.254734 |    362.016608 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 883 |    390.288065 |    433.919973 | NA                                                                                                                                                                    |
| 884 |    814.868304 |     91.924321 | Lafage                                                                                                                                                                |
| 885 |      5.715740 |     31.221866 | Birgit Szabo                                                                                                                                                          |
| 886 |    349.539580 |    781.257165 | Anthony Caravaggi                                                                                                                                                     |
| 887 |    595.952446 |    730.465168 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 888 |     52.946119 |    585.107647 | NA                                                                                                                                                                    |
| 889 |    838.863123 |      9.841513 | Gareth Monger                                                                                                                                                         |
| 890 |    835.293535 |    425.198907 | Zimices                                                                                                                                                               |
| 891 |    709.995826 |    550.574058 | T. Michael Keesey                                                                                                                                                     |
| 892 |    520.752840 |    228.323633 | Matt Crook                                                                                                                                                            |
| 893 |    885.457437 |    434.441780 | Margot Michaud                                                                                                                                                        |
| 894 |    429.094203 |    460.301104 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 895 |    846.406434 |    208.757784 | Margot Michaud                                                                                                                                                        |
| 896 |    130.143049 |    518.694486 | Scott Hartman                                                                                                                                                         |
| 897 |    423.308108 |    385.383275 | Zimices                                                                                                                                                               |
| 898 |     22.657200 |    775.169467 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 899 |     80.349371 |    668.460242 | Matt Crook                                                                                                                                                            |
| 900 |    805.940883 |    712.064029 | Zimices                                                                                                                                                               |
| 901 |    273.808603 |     20.204100 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 902 |    385.180239 |    728.867104 | NA                                                                                                                                                                    |
| 903 |    518.048802 |    311.092214 | NA                                                                                                                                                                    |
| 904 |    699.062223 |     93.142685 | Gareth Monger                                                                                                                                                         |
| 905 |    157.949726 |    249.298597 | Tracy A. Heath                                                                                                                                                        |
| 906 |    581.884894 |    380.794011 | NASA                                                                                                                                                                  |
| 907 |    490.672803 |    248.023428 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 908 |    391.090025 |    672.491250 | Zimices                                                                                                                                                               |
| 909 |    719.486653 |    711.238032 | Margot Michaud                                                                                                                                                        |
| 910 |    489.579961 |    449.878358 | Christoph Schomburg                                                                                                                                                   |
| 911 |    749.853765 |    748.464443 | Steven Traver                                                                                                                                                         |
| 912 |    791.342781 |    409.582590 | Zimices                                                                                                                                                               |
| 913 |    356.430207 |    796.499146 | Matt Crook                                                                                                                                                            |
| 914 |    313.625470 |    693.076191 | Gareth Monger                                                                                                                                                         |
| 915 |    710.731161 |    622.475464 | Jagged Fang Designs                                                                                                                                                   |
| 916 |    454.091773 |    464.687177 | T. Michael Keesey                                                                                                                                                     |
| 917 |    637.245166 |    385.218528 | Chris huh                                                                                                                                                             |
| 918 |    429.714035 |     20.474638 | Birgit Lang                                                                                                                                                           |
| 919 |    397.539966 |     62.738534 | Matt Crook                                                                                                                                                            |
| 920 |     34.976690 |    350.753314 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 921 |    545.410836 |    695.994244 | Tyler Greenfield                                                                                                                                                      |
| 922 |    497.902318 |    302.961177 | Fernando Carezzano                                                                                                                                                    |
| 923 |    681.717195 |    102.338448 | Matt Crook                                                                                                                                                            |
| 924 |    873.068413 |    263.760891 | Tracy A. Heath                                                                                                                                                        |
| 925 |     46.581289 |    253.206949 | Gareth Monger                                                                                                                                                         |
| 926 |    729.323986 |    324.705732 | Scott Hartman                                                                                                                                                         |
| 927 |    635.336871 |    155.965792 | Scott Hartman                                                                                                                                                         |
| 928 |    905.882730 |    189.051042 | Matt Crook                                                                                                                                                            |
| 929 |    575.785820 |     94.990826 | Gareth Monger                                                                                                                                                         |
| 930 |    710.225866 |    193.457358 | Caleb Brown                                                                                                                                                           |
| 931 |    769.922382 |    489.902160 | T. Michael Keesey                                                                                                                                                     |
| 932 |     39.045638 |    108.332438 | Matt Crook                                                                                                                                                            |
| 933 |      6.676342 |    203.922580 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
