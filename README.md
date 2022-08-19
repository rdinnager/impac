
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

Bruno C. Vellutini, Ignacio Contreras, Margot Michaud, Rebecca Groom,
Jose Carlos Arenas-Monroy, Noah Schlottman, photo by Gustav Paulay for
Moorea Biocode, B. Duygu Özpolat, C. Camilo Julián-Caballero, James R.
Spotila and Ray Chatterji, Birgit Lang; original image by virmisco.org,
Scott Hartman, Jagged Fang Designs, xgirouxb, Matt Crook, Adrian Reich,
FJDegrange, Zimices, Tasman Dixon, Emily Willoughby, Rene Martin, Yan
Wong, Andy Wilson, Sergio A. Muñoz-Gómez, T. Michael Keesey
(vectorization) and HuttyMcphoo (photography), Mike Keesey
(vectorization) and Vaibhavcho (photography), Steven Traver, Gareth
Monger, Caleb M. Gordon, Gabriela Palomo-Munoz, Apokryltaros (vectorized
by T. Michael Keesey), Anthony Caravaggi, Jack Mayer Wood, Yan Wong
(vectorization) from 1873 illustration, Beth Reinke, Lisa Byrne, Becky
Barnes, Milton Tan, Mali’o Kodis, traced image from the National Science
Foundation’s Turbellarian Taxonomic Database, Daniel Stadtmauer, Jaime
Headden, Nobu Tamura, vectorized by Zimices, Julie Blommaert based on
photo by Sofdrakou, Owen Jones, Matt Martyniuk, Martin R. Smith, Markus
A. Grohme, Mathieu Pélissié, Kamil S. Jaron, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Harold N Eyster, Dean Schnabel, Claus Rebler,
Caleb M. Brown, Lauren Anderson, Rafael Maia, T. Michael Keesey, Jimmy
Bernot, Shyamal, Ernst Haeckel (vectorized by T. Michael Keesey), Ferran
Sayol, L. Shyamal, Almandine (vectorized by T. Michael Keesey), Martin
Kevil, Young and Zhao (1972:figure 4), modified by Michael P. Taylor,
Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves),
Roberto Díaz Sibaja, Christopher Watson (photo) and T. Michael Keesey
(vectorization), Juan Carlos Jerí, Ludwik Gąsiorowski, Vijay Cavale
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (after C. De Muizon), Burton Robert, USFWS,
Duane Raver (vectorized by T. Michael Keesey), SauropodomorphMonarch,
Chris huh, Ingo Braasch, Michael Scroggie, DFoidl (vectorized by T.
Michael Keesey), Felix Vaux, T. Michael Keesey (vectorization) and Tony
Hisgett (photography), Caio Bernardes, vectorized by Zimices, Mathew
Wedel, Renata F. Martins, L.M. Davalos, Kanchi Nanjo, Todd Marshall,
vectorized by Zimices, Manabu Sakamoto, Roger Witter, vectorized by
Zimices, Cesar Julian, Xavier Giroux-Bougard, Michele M Tobias, Erika
Schumacher, Melissa Broussard, Joanna Wolfe, Servien (vectorized by T.
Michael Keesey), Pedro de Siracusa, Kai R. Caspar, Frederick William
Frohawk (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by T.
Michael Keesey), Matt Wilkins, Maxwell Lefroy (vectorized by T. Michael
Keesey), Andreas Hejnol, Sibi (vectorized by T. Michael Keesey), Tracy
A. Heath, Katie S. Collins, Scott Reid, Arthur Grosset (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Sharon
Wegner-Larsen, Mattia Menchetti, Alex Slavenko, Armin Reindl, Brian
Gratwicke (photo) and T. Michael Keesey (vectorization), Sam
Fraser-Smith (vectorized by T. Michael Keesey), Ghedoghedo (vectorized
by T. Michael Keesey), Mali’o Kodis, image from the Biodiversity
Heritage Library, Sarah Werning, Christoph Schomburg, Mette Aumala,
Birgit Lang, Andrew A. Farke, Fcb981 (vectorized by T. Michael Keesey),
Eyal Bartov, Jiekun He, T. Michael Keesey (after Mivart), Lukasiniho,
Scarlet23 (vectorized by T. Michael Keesey), Nobu Tamura, Conty,
Evan-Amos (vectorized by T. Michael Keesey), Collin Gross, Crystal
Maier, Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., T. Michael Keesey (after James & al.), Iain Reid, nicubunu,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), E. R. Waite & H. M. Hale (vectorized by
T. Michael Keesey), Andrew Farke and Joseph Sertich, Griensteidl and T.
Michael Keesey, Auckland Museum, Ville-Veikko Sinkkonen, Blanco et al.,
2014, vectorized by Zimices, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Tambja
(vectorized by T. Michael Keesey), Plukenet, Acrocynus (vectorized by T.
Michael Keesey), Andreas Preuss / marauder, Hans Hillewaert (photo) and
T. Michael Keesey (vectorization), Darren Naish (vectorize by T. Michael
Keesey), Mihai Dragos (vectorized by T. Michael Keesey), Jebulon
(vectorized by T. Michael Keesey), Henry Lydecker, Dmitry Bogdanov,
Cristina Guijarro, Robert Gay, modifed from Olegivvit, Michelle Site,
Elisabeth Östman, Inessa Voet, Cristopher Silva, T. Michael Keesey
(vectorization) and Nadiatalent (photography), (after Spotila 2004),
Maija Karala, Mark Hofstetter (vectorized by T. Michael Keesey), Sarah
Alewijnse, Mo Hassan, Oscar Sanisidro, Jerry Oldenettel (vectorized by
T. Michael Keesey), DW Bapst (modified from Bulman, 1970), Tony Ayling
(vectorized by T. Michael Keesey), Wayne Decatur, Doug Backlund (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Meliponicultor Itaymbere, Kanako Bessho-Uehara, Mason McNair, S.Martini,
Trond R. Oskars, Carlos Cano-Barbacil, Maxime Dahirel, Michael P.
Taylor, Nobu Tamura (modified by T. Michael Keesey), Geoff Shaw, Dennis
C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Robert Bruce Horsfall, vectorized by Zimices, FunkMonk, Steven Haddock
• Jellywatch.org, Matt Celeskey, Verisimilus, NASA, Mali’o Kodis,
image from Brockhaus and Efron Encyclopedic Dictionary, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Jim Bendon (photography) and T. Michael Keesey (vectorization),
Charles Doolittle Walcott (vectorized by T. Michael Keesey), Raven Amos,
Hugo Gruson, Smokeybjb, M Kolmann, C. Abraczinskas, Frank Förster (based
on a picture by Jerry Kirkhart; modified by T. Michael Keesey), Ghedo
(vectorized by T. Michael Keesey), Tauana J. Cunha, Michael B. H.
(vectorized by T. Michael Keesey), Joseph Smit (modified by T. Michael
Keesey), Hans Hillewaert, SecretJellyMan, Robert Hering, Gustav Mützel,
David Liao, Haplochromis (vectorized by T. Michael Keesey), Riccardo
Percudani, Emma Hughes, Scott Hartman (modified by T. Michael Keesey),
Ben Liebeskind, Stanton F. Fink (vectorized by T. Michael Keesey), Qiang
Ou, Lily Hughes, Mathilde Cordellier, Christine Axon, Peileppe, John
Curtis (vectorized by T. Michael Keesey), Sam Droege (photography) and
T. Michael Keesey (vectorization), Remes K, Ortega F, Fierro I, Joger U,
Kosma R, et al., Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, T.
Michael Keesey (after Marek Velechovský), Matt Dempsey, Alyssa Bell &
Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690, T. Michael
Keesey (photo by Darren Swim), Chris Jennings (Risiatto), Mali’o Kodis,
photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Frank Förster
(based on a picture by Hans Hillewaert), CNZdenek, Falconaumanni and T.
Michael Keesey, JCGiron, David Orr, Philip Chalmers (vectorized by T.
Michael Keesey), Meyers Konversations-Lexikon 1897 (vectorized: Yan
Wong), Chuanixn Yu, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), White Wolf, Gabriel Lio, vectorized by Zimices, Mali’o
Kodis, photograph by P. Funch and R.M. Kristensen, Fernando Carezzano,
Noah Schlottman, photo by Casey Dunn, Espen Horn (model; vectorized by
T. Michael Keesey from a photo by H. Zell), Vanessa Guerra, Amanda
Katzer, Roberto Diaz Sibaja, based on Domser, Smokeybjb (modified by
Mike Keesey), Alexandre Vong, Sean McCann, Manabu Bessho-Uehara, Julio
Garza, Mariana Ruiz Villarreal, Dave Angelini, Richard Parker
(vectorized by T. Michael Keesey), Roule Jammes (vectorized by T.
Michael Keesey), Taro Maeda, G. M. Woodward, Robert Gay, Heinrich Harder
(vectorized by T. Michael Keesey), Ieuan Jones, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Blair Perry, Jakovche, DW Bapst, modified from Figure 1 of
Belanger (2011, PALAIOS)., Tod Robbins, Smokeybjb, vectorized by
Zimices, Courtney Rockenbach, Benjamint444, Chase Brownstein, Pranav
Iyer (grey ideas), Didier Descouens (vectorized by T. Michael Keesey),
Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe,
Smokeybjb (vectorized by T. Michael Keesey), A. R. McCulloch (vectorized
by T. Michael Keesey), M. A. Broussard, Mali’o Kodis, photograph by G.
Giribet, T. Michael Keesey (vectorization) and Larry Loos (photography),
Yan Wong from drawing by T. F. Zimmermann, Javiera Constanzo, Giant Blue
Anteater (vectorized by T. Michael Keesey), Noah Schlottman, H. Filhol
(vectorized by T. Michael Keesey), Smokeybjb (modified by T. Michael
Keesey), Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of
Land Mammals in the Western Hemisphere”, Neil Kelley, LeonardoG
(photography) and T. Michael Keesey (vectorization), Renato Santos, Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    654.148140 |    518.879609 | Bruno C. Vellutini                                                                                                                                                              |
|   2 |    420.344821 |    151.088510 | Ignacio Contreras                                                                                                                                                               |
|   3 |    915.345412 |    318.961247 | Margot Michaud                                                                                                                                                                  |
|   4 |    531.825840 |    624.408323 | NA                                                                                                                                                                              |
|   5 |    105.856362 |    365.520038 | Rebecca Groom                                                                                                                                                                   |
|   6 |    318.117456 |    228.432619 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|   7 |    724.880500 |    159.629356 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                      |
|   8 |    141.769814 |    150.920784 | NA                                                                                                                                                                              |
|   9 |    115.785250 |    694.707679 | B. Duygu Özpolat                                                                                                                                                                |
|  10 |    488.862833 |    204.662663 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  11 |    493.349797 |    434.409276 | James R. Spotila and Ray Chatterji                                                                                                                                              |
|  12 |    249.116248 |     51.992885 | Birgit Lang; original image by virmisco.org                                                                                                                                     |
|  13 |    872.184676 |    553.591495 | NA                                                                                                                                                                              |
|  14 |    895.249137 |    231.637793 | Scott Hartman                                                                                                                                                                   |
|  15 |    743.716148 |    719.651330 | Jagged Fang Designs                                                                                                                                                             |
|  16 |    320.590709 |    650.300092 | xgirouxb                                                                                                                                                                        |
|  17 |    453.300659 |    348.220009 | Matt Crook                                                                                                                                                                      |
|  18 |    295.242067 |    383.155562 | Adrian Reich                                                                                                                                                                    |
|  19 |    790.212010 |    362.728030 | NA                                                                                                                                                                              |
|  20 |    698.449304 |    498.503064 | FJDegrange                                                                                                                                                                      |
|  21 |    392.427172 |    764.621185 | Ignacio Contreras                                                                                                                                                               |
|  22 |    939.656617 |    645.234902 | Zimices                                                                                                                                                                         |
|  23 |    393.858035 |    557.065702 | Tasman Dixon                                                                                                                                                                    |
|  24 |    605.586242 |    282.610703 | Emily Willoughby                                                                                                                                                                |
|  25 |    241.736514 |    701.489929 | Rene Martin                                                                                                                                                                     |
|  26 |    526.997051 |     34.274411 | Zimices                                                                                                                                                                         |
|  27 |    969.314757 |    479.560963 | Yan Wong                                                                                                                                                                        |
|  28 |    221.009642 |    525.234656 | Andy Wilson                                                                                                                                                                     |
|  29 |    842.619201 |     90.430481 | NA                                                                                                                                                                              |
|  30 |    692.263879 |     66.563447 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
|  31 |    891.320334 |    135.798919 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                                 |
|  32 |    777.215097 |    254.176312 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                        |
|  33 |    778.069327 |    657.165970 | Steven Traver                                                                                                                                                                   |
|  34 |    355.109848 |    112.460938 | Jagged Fang Designs                                                                                                                                                             |
|  35 |    615.301195 |    127.751662 | Steven Traver                                                                                                                                                                   |
|  36 |    852.250448 |    467.482305 | Gareth Monger                                                                                                                                                                   |
|  37 |    561.098118 |    731.534542 | NA                                                                                                                                                                              |
|  38 |    626.925909 |    694.673531 | NA                                                                                                                                                                              |
|  39 |    128.007525 |    595.283765 | Caleb M. Gordon                                                                                                                                                                 |
|  40 |    920.399580 |     51.350263 | Zimices                                                                                                                                                                         |
|  41 |    880.987284 |    727.543339 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  42 |    456.010055 |    703.519269 | Gareth Monger                                                                                                                                                                   |
|  43 |    223.471126 |    635.661024 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
|  44 |    685.953660 |    390.655957 | Anthony Caravaggi                                                                                                                                                               |
|  45 |    175.366037 |    281.810085 | Jack Mayer Wood                                                                                                                                                                 |
|  46 |    446.966635 |    294.493751 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                 |
|  47 |     63.320863 |    458.303108 | Beth Reinke                                                                                                                                                                     |
|  48 |    162.250049 |    743.952160 | Jagged Fang Designs                                                                                                                                                             |
|  49 |    562.441152 |    521.605755 | Lisa Byrne                                                                                                                                                                      |
|  50 |    559.432841 |    314.509933 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  51 |    436.414948 |    488.382263 | xgirouxb                                                                                                                                                                        |
|  52 |    162.561146 |    230.445991 | Gareth Monger                                                                                                                                                                   |
|  53 |    813.177112 |    589.501761 | Gareth Monger                                                                                                                                                                   |
|  54 |    372.577850 |     37.626575 | Becky Barnes                                                                                                                                                                    |
|  55 |    793.067205 |    510.116838 | Milton Tan                                                                                                                                                                      |
|  56 |     49.708185 |    605.102521 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                               |
|  57 |    739.872345 |    777.059543 | Scott Hartman                                                                                                                                                                   |
|  58 |    947.207478 |    171.269787 | Steven Traver                                                                                                                                                                   |
|  59 |    360.210171 |    714.783563 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  60 |    626.736780 |    780.306101 | Daniel Stadtmauer                                                                                                                                                               |
|  61 |    209.704087 |    328.514106 | Jaime Headden                                                                                                                                                                   |
|  62 |    497.709349 |     92.583471 | Tasman Dixon                                                                                                                                                                    |
|  63 |    274.173509 |    781.076323 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  64 |    889.172919 |    391.526921 | Julie Blommaert based on photo by Sofdrakou                                                                                                                                     |
|  65 |     66.090664 |    762.209132 | Scott Hartman                                                                                                                                                                   |
|  66 |    552.327951 |    555.516245 | Gareth Monger                                                                                                                                                                   |
|  67 |    623.391963 |    204.753911 | Scott Hartman                                                                                                                                                                   |
|  68 |    191.748700 |    402.321266 | Jagged Fang Designs                                                                                                                                                             |
|  69 |    773.157578 |     78.717236 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  70 |    259.508053 |    738.763388 | Owen Jones                                                                                                                                                                      |
|  71 |    460.968273 |    567.580801 | Matt Martyniuk                                                                                                                                                                  |
|  72 |    183.795175 |    628.707416 | Matt Crook                                                                                                                                                                      |
|  73 |    276.477929 |     98.335383 | Martin R. Smith                                                                                                                                                                 |
|  74 |    717.841694 |    755.643076 | Zimices                                                                                                                                                                         |
|  75 |    857.811064 |    266.990237 | Zimices                                                                                                                                                                         |
|  76 |    423.226740 |    185.349781 | Markus A. Grohme                                                                                                                                                                |
|  77 |    779.410259 |    401.214913 | Mathieu Pélissié                                                                                                                                                                |
|  78 |    578.071714 |    583.704070 | Andy Wilson                                                                                                                                                                     |
|  79 |    846.044592 |    151.663054 | Kamil S. Jaron                                                                                                                                                                  |
|  80 |    895.094766 |    366.290668 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  81 |    114.267607 |    665.309287 | Harold N Eyster                                                                                                                                                                 |
|  82 |    571.590548 |    169.647848 | Steven Traver                                                                                                                                                                   |
|  83 |    420.620398 |     74.596568 | Dean Schnabel                                                                                                                                                                   |
|  84 |    958.781551 |    256.463155 | Claus Rebler                                                                                                                                                                    |
|  85 |    998.633983 |    751.448196 | Margot Michaud                                                                                                                                                                  |
|  86 |    657.614352 |    243.894006 | Caleb M. Brown                                                                                                                                                                  |
|  87 |    180.914902 |    754.095252 | Gareth Monger                                                                                                                                                                   |
|  88 |   1002.118231 |    718.745959 | Zimices                                                                                                                                                                         |
|  89 |    657.149355 |    735.410870 | Matt Crook                                                                                                                                                                      |
|  90 |    146.890345 |     26.028191 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  91 |    482.400914 |    382.784615 | Lauren Anderson                                                                                                                                                                 |
|  92 |    751.798513 |    102.726308 | Rafael Maia                                                                                                                                                                     |
|  93 |    433.231811 |    706.719515 | Scott Hartman                                                                                                                                                                   |
|  94 |     36.281062 |    169.107896 | Matt Crook                                                                                                                                                                      |
|  95 |    349.733264 |    462.568768 | Mathieu Pélissié                                                                                                                                                                |
|  96 |    976.532006 |    235.430095 | T. Michael Keesey                                                                                                                                                               |
|  97 |    693.327418 |    272.814322 | T. Michael Keesey                                                                                                                                                               |
|  98 |    692.075012 |    161.103098 | Jimmy Bernot                                                                                                                                                                    |
|  99 |    937.597855 |    164.878490 | Ignacio Contreras                                                                                                                                                               |
| 100 |    175.278143 |    780.617094 | Shyamal                                                                                                                                                                         |
| 101 |    484.052533 |    127.694869 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 102 |    282.173867 |    548.678091 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 103 |    861.837551 |    197.699184 | Steven Traver                                                                                                                                                                   |
| 104 |    587.944625 |    764.516274 | NA                                                                                                                                                                              |
| 105 |     49.151312 |     17.352550 | Ferran Sayol                                                                                                                                                                    |
| 106 |    855.148481 |    625.631065 | L. Shyamal                                                                                                                                                                      |
| 107 |    452.906773 |    545.198063 | Steven Traver                                                                                                                                                                   |
| 108 |    166.254170 |    613.889100 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                     |
| 109 |    547.577123 |    493.477352 | Martin Kevil                                                                                                                                                                    |
| 110 |    953.429080 |    123.101829 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                   |
| 111 |    759.552077 |    454.842906 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                             |
| 112 |    617.925099 |    479.631354 | Roberto Díaz Sibaja                                                                                                                                                             |
| 113 |     58.399053 |    280.865726 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                |
| 114 |    998.472338 |    214.503958 | Anthony Caravaggi                                                                                                                                                               |
| 115 |    251.984596 |    127.980757 | T. Michael Keesey                                                                                                                                                               |
| 116 |    613.003413 |     97.655057 | Juan Carlos Jerí                                                                                                                                                                |
| 117 |    763.033211 |     22.346457 | Ludwik Gąsiorowski                                                                                                                                                              |
| 118 |    650.908835 |    273.950738 | Jagged Fang Designs                                                                                                                                                             |
| 119 |     96.761116 |    278.175124 | Matt Crook                                                                                                                                                                      |
| 120 |    962.374886 |    199.208467 | Jagged Fang Designs                                                                                                                                                             |
| 121 |    103.008883 |    432.438175 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                    |
| 122 |    459.284618 |    790.826203 | T. Michael Keesey (after C. De Muizon)                                                                                                                                          |
| 123 |    742.852112 |    580.488017 | Gareth Monger                                                                                                                                                                   |
| 124 |    134.572075 |     59.161018 | Burton Robert, USFWS                                                                                                                                                            |
| 125 |    610.530962 |    685.588487 | Tasman Dixon                                                                                                                                                                    |
| 126 |    977.738410 |     98.786189 | Matt Crook                                                                                                                                                                      |
| 127 |    725.996525 |    660.159644 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                   |
| 128 |    787.599608 |    738.715509 | Markus A. Grohme                                                                                                                                                                |
| 129 |    637.475039 |    352.898659 | Jaime Headden                                                                                                                                                                   |
| 130 |    722.805891 |    689.224956 | SauropodomorphMonarch                                                                                                                                                           |
| 131 |    238.139598 |    141.061516 | Margot Michaud                                                                                                                                                                  |
| 132 |    777.824173 |    788.700692 | Gareth Monger                                                                                                                                                                   |
| 133 |    525.806398 |     63.198745 | Chris huh                                                                                                                                                                       |
| 134 |    930.405470 |     94.285088 | Ingo Braasch                                                                                                                                                                    |
| 135 |     83.515180 |     20.760633 | Scott Hartman                                                                                                                                                                   |
| 136 |    975.360542 |    379.831023 | Milton Tan                                                                                                                                                                      |
| 137 |    786.077964 |     10.271368 | Michael Scroggie                                                                                                                                                                |
| 138 |    936.266344 |    524.088024 | Margot Michaud                                                                                                                                                                  |
| 139 |     61.244813 |    225.178663 | Gareth Monger                                                                                                                                                                   |
| 140 |    438.815692 |    129.321309 | Zimices                                                                                                                                                                         |
| 141 |    715.308576 |    359.979277 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                        |
| 142 |    634.352470 |     57.611806 | Matt Crook                                                                                                                                                                      |
| 143 |     16.083148 |    275.444838 | NA                                                                                                                                                                              |
| 144 |    689.232355 |    324.001364 | Michael Scroggie                                                                                                                                                                |
| 145 |    314.258775 |    438.084981 | Margot Michaud                                                                                                                                                                  |
| 146 |     25.097349 |    118.815843 | Andy Wilson                                                                                                                                                                     |
| 147 |    900.008467 |    490.929940 | Felix Vaux                                                                                                                                                                      |
| 148 |     39.650935 |    700.899661 | Zimices                                                                                                                                                                         |
| 149 |    363.794671 |    498.790262 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                                |
| 150 |    884.761905 |      4.221244 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 151 |    869.373827 |     23.344484 | Mathew Wedel                                                                                                                                                                    |
| 152 |    737.024264 |    434.833346 | Chris huh                                                                                                                                                                       |
| 153 |      9.465752 |    528.358307 | Renata F. Martins                                                                                                                                                               |
| 154 |   1000.627038 |    244.362300 | L.M. Davalos                                                                                                                                                                    |
| 155 |    865.186841 |    285.831941 | Kanchi Nanjo                                                                                                                                                                    |
| 156 |    622.425358 |    733.519059 | Gareth Monger                                                                                                                                                                   |
| 157 |    213.863511 |    793.099957 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 158 |     74.816187 |    262.416745 | Mathieu Pélissié                                                                                                                                                                |
| 159 |    254.212485 |    215.147799 | Andy Wilson                                                                                                                                                                     |
| 160 |    105.065051 |    597.045218 | Jaime Headden                                                                                                                                                                   |
| 161 |    248.993820 |    109.195364 | Markus A. Grohme                                                                                                                                                                |
| 162 |    875.412431 |    276.137033 | Dean Schnabel                                                                                                                                                                   |
| 163 |    304.547583 |    502.160260 | Manabu Sakamoto                                                                                                                                                                 |
| 164 |    727.938864 |    132.594133 | Matt Crook                                                                                                                                                                      |
| 165 |    680.988238 |    615.973678 | Roger Witter, vectorized by Zimices                                                                                                                                             |
| 166 |    696.732079 |    620.234654 | Cesar Julian                                                                                                                                                                    |
| 167 |    619.458169 |    589.399968 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 168 |    455.500388 |    556.210728 | Xavier Giroux-Bougard                                                                                                                                                           |
| 169 |    595.074830 |    486.858537 | Matt Crook                                                                                                                                                                      |
| 170 |    791.811819 |    322.963071 | Scott Hartman                                                                                                                                                                   |
| 171 |     12.906587 |    489.122216 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 172 |    468.993738 |    617.254720 | T. Michael Keesey                                                                                                                                                               |
| 173 |    383.146101 |     95.954516 | Steven Traver                                                                                                                                                                   |
| 174 |    884.605478 |    519.314631 | Margot Michaud                                                                                                                                                                  |
| 175 |    667.009457 |    530.168457 | Ignacio Contreras                                                                                                                                                               |
| 176 |    601.589632 |    439.418124 | Michele M Tobias                                                                                                                                                                |
| 177 |    127.229610 |    544.585737 | Dean Schnabel                                                                                                                                                                   |
| 178 |    324.225231 |    729.957236 | Erika Schumacher                                                                                                                                                                |
| 179 |    760.154361 |     44.055264 | Melissa Broussard                                                                                                                                                               |
| 180 |     82.710471 |    475.546354 | Joanna Wolfe                                                                                                                                                                    |
| 181 |    964.127471 |    753.808795 | Servien (vectorized by T. Michael Keesey)                                                                                                                                       |
| 182 |    191.731518 |    259.479110 | Pedro de Siracusa                                                                                                                                                               |
| 183 |    990.180273 |     69.041282 | Zimices                                                                                                                                                                         |
| 184 |     94.799656 |    628.567641 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 185 |    192.538150 |    146.578573 | Kai R. Caspar                                                                                                                                                                   |
| 186 |     95.039621 |     43.884550 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                     |
| 187 |    775.418370 |    530.177327 | Steven Traver                                                                                                                                                                   |
| 188 |    481.687601 |     77.624562 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 189 |    378.158610 |    620.436013 | Andy Wilson                                                                                                                                                                     |
| 190 |    917.025752 |    569.692182 | Jagged Fang Designs                                                                                                                                                             |
| 191 |    734.832405 |    680.697374 | Gareth Monger                                                                                                                                                                   |
| 192 |    167.306894 |    434.742541 | Matt Wilkins                                                                                                                                                                    |
| 193 |    407.241486 |    631.735719 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 194 |    903.536964 |    692.674715 | Andreas Hejnol                                                                                                                                                                  |
| 195 |    281.782842 |    424.277371 | xgirouxb                                                                                                                                                                        |
| 196 |    985.150216 |    157.075405 | Mathew Wedel                                                                                                                                                                    |
| 197 |    251.997767 |    671.220978 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 198 |    913.835178 |    268.662012 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 199 |    402.315579 |    670.654381 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 200 |    394.913463 |    550.420144 | Tracy A. Heath                                                                                                                                                                  |
| 201 |    979.920326 |    321.516730 | Katie S. Collins                                                                                                                                                                |
| 202 |    378.845332 |    338.335599 | Scott Reid                                                                                                                                                                      |
| 203 |    170.775234 |     73.103413 | Rebecca Groom                                                                                                                                                                   |
| 204 |    951.780108 |    579.136532 | Andy Wilson                                                                                                                                                                     |
| 205 |    583.071457 |    408.975625 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                  |
| 206 |    327.296724 |    492.796259 | Ferran Sayol                                                                                                                                                                    |
| 207 |    351.260885 |    327.771570 | Sharon Wegner-Larsen                                                                                                                                                            |
| 208 |     75.308871 |    386.431279 | T. Michael Keesey                                                                                                                                                               |
| 209 |    692.597441 |    600.811431 | Zimices                                                                                                                                                                         |
| 210 |    924.787679 |    581.534801 | Scott Hartman                                                                                                                                                                   |
| 211 |    388.845347 |    537.325307 | Jagged Fang Designs                                                                                                                                                             |
| 212 |    697.269283 |    737.558083 | Margot Michaud                                                                                                                                                                  |
| 213 |    976.874320 |    365.698042 | Mattia Menchetti                                                                                                                                                                |
| 214 |    102.011368 |    761.041624 | Jagged Fang Designs                                                                                                                                                             |
| 215 |     38.706023 |    236.489075 | SauropodomorphMonarch                                                                                                                                                           |
| 216 |    308.195039 |    569.151285 | Alex Slavenko                                                                                                                                                                   |
| 217 |     34.264282 |    546.293215 | Armin Reindl                                                                                                                                                                    |
| 218 |    845.946708 |     15.662831 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 219 |     24.542491 |    100.078459 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 220 |    662.400822 |    519.745519 | Matt Crook                                                                                                                                                                      |
| 221 |    923.083343 |    709.027461 | Zimices                                                                                                                                                                         |
| 222 |    752.203055 |    525.252790 | Gareth Monger                                                                                                                                                                   |
| 223 |    993.995059 |    734.904422 | Margot Michaud                                                                                                                                                                  |
| 224 |    675.062505 |    281.317267 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                              |
| 225 |    461.946630 |    459.509318 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 226 |    232.477249 |    737.087140 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                      |
| 227 |    433.082154 |    341.937799 | Sarah Werning                                                                                                                                                                   |
| 228 |    398.176551 |    526.051244 | Christoph Schomburg                                                                                                                                                             |
| 229 |    495.952120 |    357.317594 | Mette Aumala                                                                                                                                                                    |
| 230 |    374.804597 |    395.845167 | Markus A. Grohme                                                                                                                                                                |
| 231 |    477.367799 |    737.856663 | Birgit Lang                                                                                                                                                                     |
| 232 |    488.698466 |    300.189711 | Scott Hartman                                                                                                                                                                   |
| 233 |    332.706691 |    746.089604 | Andrew A. Farke                                                                                                                                                                 |
| 234 |    482.288234 |    782.097349 | Zimices                                                                                                                                                                         |
| 235 |    245.906347 |     94.408963 | Ferran Sayol                                                                                                                                                                    |
| 236 |    851.366249 |     36.308863 | Kamil S. Jaron                                                                                                                                                                  |
| 237 |     11.027595 |    124.117167 | Zimices                                                                                                                                                                         |
| 238 |    639.574724 |    621.944281 | Tracy A. Heath                                                                                                                                                                  |
| 239 |    403.308399 |     64.239047 | Kanchi Nanjo                                                                                                                                                                    |
| 240 |    379.926422 |    368.638703 | Christoph Schomburg                                                                                                                                                             |
| 241 |    706.594141 |      6.609497 | SauropodomorphMonarch                                                                                                                                                           |
| 242 |    679.737399 |    229.369154 | Birgit Lang                                                                                                                                                                     |
| 243 |    199.588996 |     58.159886 | Jagged Fang Designs                                                                                                                                                             |
| 244 |    997.889806 |     47.563502 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 245 |    391.178407 |    184.022442 | Gareth Monger                                                                                                                                                                   |
| 246 |     32.117191 |    655.563158 | Matt Martyniuk                                                                                                                                                                  |
| 247 |     76.602808 |    610.048981 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                                        |
| 248 |    795.934402 |     55.906099 | Tasman Dixon                                                                                                                                                                    |
| 249 |    296.129213 |    328.958738 | Eyal Bartov                                                                                                                                                                     |
| 250 |    406.481108 |    649.382172 | Zimices                                                                                                                                                                         |
| 251 |     82.730633 |    526.348843 | Gareth Monger                                                                                                                                                                   |
| 252 |    141.164700 |    619.814516 | Jiekun He                                                                                                                                                                       |
| 253 |    943.688676 |    371.927072 | Matt Crook                                                                                                                                                                      |
| 254 |     12.130045 |    635.897420 | Zimices                                                                                                                                                                         |
| 255 |    741.341731 |    470.408611 | T. Michael Keesey (after Mivart)                                                                                                                                                |
| 256 |    337.078099 |    446.565893 | Ferran Sayol                                                                                                                                                                    |
| 257 |    759.763297 |    211.802900 | Zimices                                                                                                                                                                         |
| 258 |    429.581974 |    566.126902 | Lukasiniho                                                                                                                                                                      |
| 259 |    431.025595 |    639.507737 | Scott Hartman                                                                                                                                                                   |
| 260 |    216.043067 |    446.207724 | Birgit Lang; original image by virmisco.org                                                                                                                                     |
| 261 |    504.013846 |    691.742155 | NA                                                                                                                                                                              |
| 262 |     26.142083 |    725.896423 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 263 |     53.966985 |     33.809923 | Ferran Sayol                                                                                                                                                                    |
| 264 |     43.049593 |     67.500588 | Scott Hartman                                                                                                                                                                   |
| 265 |    768.942247 |    126.195081 | Nobu Tamura                                                                                                                                                                     |
| 266 |    900.259792 |    589.167093 | Zimices                                                                                                                                                                         |
| 267 |    209.726935 |     93.214138 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 268 |    888.583233 |    674.873022 | Conty                                                                                                                                                                           |
| 269 |    819.999106 |    422.060728 | T. Michael Keesey                                                                                                                                                               |
| 270 |    637.334969 |    541.981684 | Zimices                                                                                                                                                                         |
| 271 |    127.817598 |    480.852679 | L. Shyamal                                                                                                                                                                      |
| 272 |    304.055892 |    492.460313 | Zimices                                                                                                                                                                         |
| 273 |      8.267941 |    309.391950 | Sarah Werning                                                                                                                                                                   |
| 274 |    974.874923 |    782.242146 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 275 |    487.240394 |    271.171685 | L. Shyamal                                                                                                                                                                      |
| 276 |    248.258459 |    764.068897 | NA                                                                                                                                                                              |
| 277 |    235.920987 |    617.405044 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 278 |    217.780328 |    379.839486 | Cesar Julian                                                                                                                                                                    |
| 279 |   1015.601580 |    494.074602 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 280 |    852.645691 |    537.205622 | Collin Gross                                                                                                                                                                    |
| 281 |    827.988508 |    255.646571 | Matt Crook                                                                                                                                                                      |
| 282 |    791.105187 |    544.826133 | Crystal Maier                                                                                                                                                                   |
| 283 |    991.250575 |    343.985057 | Kai R. Caspar                                                                                                                                                                   |
| 284 |    303.381333 |    740.654602 | T. Michael Keesey                                                                                                                                                               |
| 285 |    652.064851 |    221.573362 | Matt Crook                                                                                                                                                                      |
| 286 |    153.448326 |    249.229482 | Joanna Wolfe                                                                                                                                                                    |
| 287 |    931.091954 |    597.642390 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                        |
| 288 |    438.869901 |    176.873243 | Jagged Fang Designs                                                                                                                                                             |
| 289 |     34.104201 |    367.691848 | Kamil S. Jaron                                                                                                                                                                  |
| 290 |    311.707965 |    429.582370 | Jagged Fang Designs                                                                                                                                                             |
| 291 |     52.116873 |    243.632135 | Harold N Eyster                                                                                                                                                                 |
| 292 |    996.957748 |    613.328241 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 293 |    816.712791 |    778.445075 | Steven Traver                                                                                                                                                                   |
| 294 |    678.906255 |    631.861446 | Chris huh                                                                                                                                                                       |
| 295 |    520.056466 |    701.225128 | Jaime Headden                                                                                                                                                                   |
| 296 |    204.686455 |     28.018310 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 297 |     26.621743 |    136.244564 | Felix Vaux                                                                                                                                                                      |
| 298 |    131.543816 |    258.081748 | Iain Reid                                                                                                                                                                       |
| 299 |    344.490947 |    160.507966 | nicubunu                                                                                                                                                                        |
| 300 |     79.918169 |    403.073800 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 301 |    809.552049 |    732.604281 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                      |
| 302 |    366.074877 |    423.137038 | Scott Hartman                                                                                                                                                                   |
| 303 |    937.814879 |    721.402148 | Andrew Farke and Joseph Sertich                                                                                                                                                 |
| 304 |    852.177468 |    291.748631 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 305 |    416.701550 |    379.977448 | Caleb M. Brown                                                                                                                                                                  |
| 306 |   1006.689182 |    666.350053 | Roberto Díaz Sibaja                                                                                                                                                             |
| 307 |    424.775004 |    787.052305 | Auckland Museum                                                                                                                                                                 |
| 308 |    958.515590 |    337.461189 | Steven Traver                                                                                                                                                                   |
| 309 |     86.347050 |    146.016532 | Matt Crook                                                                                                                                                                      |
| 310 |    364.020556 |    122.628219 | NA                                                                                                                                                                              |
| 311 |    863.451939 |     67.799371 | Jack Mayer Wood                                                                                                                                                                 |
| 312 |    279.569601 |    235.750235 | Gareth Monger                                                                                                                                                                   |
| 313 |    227.166084 |    436.654612 | T. Michael Keesey                                                                                                                                                               |
| 314 |    961.633129 |    787.890565 | Ville-Veikko Sinkkonen                                                                                                                                                          |
| 315 |    243.588998 |    183.017530 | Jaime Headden                                                                                                                                                                   |
| 316 |     39.956479 |    416.404419 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 317 |    308.593033 |    578.807237 | NA                                                                                                                                                                              |
| 318 |    517.596564 |    122.788187 | Melissa Broussard                                                                                                                                                               |
| 319 |    256.914795 |    265.375342 | Steven Traver                                                                                                                                                                   |
| 320 |    524.002934 |    537.279045 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                      |
| 321 |    593.457538 |    472.535021 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 322 |    821.530993 |    171.553855 | Gareth Monger                                                                                                                                                                   |
| 323 |    754.031404 |    722.249752 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                        |
| 324 |    754.802282 |    359.039388 | NA                                                                                                                                                                              |
| 325 |    574.447840 |    221.461197 | Gareth Monger                                                                                                                                                                   |
| 326 |    647.377411 |    300.242797 | NA                                                                                                                                                                              |
| 327 |    832.504213 |    476.873336 | Ferran Sayol                                                                                                                                                                    |
| 328 |      9.800529 |     31.750390 | Matt Crook                                                                                                                                                                      |
| 329 |    533.522599 |    146.295162 | Margot Michaud                                                                                                                                                                  |
| 330 |    468.194009 |    646.856566 | Ferran Sayol                                                                                                                                                                    |
| 331 |    540.180223 |    479.581466 | NA                                                                                                                                                                              |
| 332 |    368.812104 |    523.428240 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 333 |    505.320755 |     69.245983 | Plukenet                                                                                                                                                                        |
| 334 |    413.087982 |    346.625269 | Kamil S. Jaron                                                                                                                                                                  |
| 335 |    895.117524 |    446.987812 | Steven Traver                                                                                                                                                                   |
| 336 |    804.869484 |     18.232489 | Margot Michaud                                                                                                                                                                  |
| 337 |      4.204243 |    711.678917 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                     |
| 338 |     99.432022 |    747.288406 | Andy Wilson                                                                                                                                                                     |
| 339 |    334.226417 |     90.430622 | Steven Traver                                                                                                                                                                   |
| 340 |    164.521234 |    447.737465 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 341 |    459.703137 |     53.994943 | Andreas Preuss / marauder                                                                                                                                                       |
| 342 |    147.091593 |    712.924390 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 343 |    962.626550 |    146.912932 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 344 |     93.175685 |    540.624062 | Sarah Werning                                                                                                                                                                   |
| 345 |    837.102331 |    389.793726 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 346 |    728.692287 |     16.875266 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 347 |    220.779983 |    259.095661 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 348 |    880.597428 |    451.046610 | Chris huh                                                                                                                                                                       |
| 349 |    826.740702 |     36.958629 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 350 |    657.376694 |    540.773077 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                       |
| 351 |    652.908702 |     17.834624 | Henry Lydecker                                                                                                                                                                  |
| 352 |   1006.280252 |    487.432020 | Dmitry Bogdanov                                                                                                                                                                 |
| 353 |    790.495757 |     67.580035 | Dmitry Bogdanov                                                                                                                                                                 |
| 354 |    708.084436 |    228.275256 | Cristina Guijarro                                                                                                                                                               |
| 355 |    191.829522 |    366.797295 | Robert Gay, modifed from Olegivvit                                                                                                                                              |
| 356 |     93.187132 |    666.875167 | Joanna Wolfe                                                                                                                                                                    |
| 357 |    317.269921 |    745.926627 | Zimices                                                                                                                                                                         |
| 358 |    774.731853 |    546.424603 | L. Shyamal                                                                                                                                                                      |
| 359 |    741.801959 |    224.650218 | Zimices                                                                                                                                                                         |
| 360 |   1004.425091 |    699.582129 | Ferran Sayol                                                                                                                                                                    |
| 361 |    822.487081 |    153.146192 | Michelle Site                                                                                                                                                                   |
| 362 |    121.983871 |    764.791520 | Markus A. Grohme                                                                                                                                                                |
| 363 |    347.290846 |    502.525985 | Elisabeth Östman                                                                                                                                                                |
| 364 |   1000.363571 |     85.720911 | Inessa Voet                                                                                                                                                                     |
| 365 |    979.928976 |    597.633469 | Scott Hartman                                                                                                                                                                   |
| 366 |    705.698385 |    600.743581 | Ferran Sayol                                                                                                                                                                    |
| 367 |    881.114094 |    573.676043 | Margot Michaud                                                                                                                                                                  |
| 368 |    568.758878 |    449.901143 | Markus A. Grohme                                                                                                                                                                |
| 369 |    453.982931 |    520.608192 | Zimices                                                                                                                                                                         |
| 370 |     68.988924 |     31.815270 | Steven Traver                                                                                                                                                                   |
| 371 |    588.666507 |     40.444400 | Margot Michaud                                                                                                                                                                  |
| 372 |    312.642688 |    132.689851 | Cristopher Silva                                                                                                                                                                |
| 373 |    766.342473 |    593.162844 | Zimices                                                                                                                                                                         |
| 374 |    320.085546 |    553.929036 | Scott Hartman                                                                                                                                                                   |
| 375 |    288.318845 |    584.474730 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                 |
| 376 |    318.268841 |      9.094993 | NA                                                                                                                                                                              |
| 377 |   1003.672906 |    267.181749 | Zimices                                                                                                                                                                         |
| 378 |    223.427853 |    167.072353 | Steven Traver                                                                                                                                                                   |
| 379 |    479.676109 |    657.329809 | (after Spotila 2004)                                                                                                                                                            |
| 380 |    898.445927 |     86.192469 | Maija Karala                                                                                                                                                                    |
| 381 |    682.534344 |    214.942874 | NA                                                                                                                                                                              |
| 382 |    615.775045 |    388.560839 | NA                                                                                                                                                                              |
| 383 |      4.534888 |    790.222341 | T. Michael Keesey                                                                                                                                                               |
| 384 |    158.057622 |    704.906501 | Steven Traver                                                                                                                                                                   |
| 385 |    833.881989 |    403.635577 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                               |
| 386 |    435.907915 |    167.507078 | Sarah Alewijnse                                                                                                                                                                 |
| 387 |    464.654682 |    660.157383 | Gareth Monger                                                                                                                                                                   |
| 388 |    803.865788 |    755.988870 | Gareth Monger                                                                                                                                                                   |
| 389 |    132.079680 |    213.051778 | Zimices                                                                                                                                                                         |
| 390 |    245.505402 |    243.366957 | Mo Hassan                                                                                                                                                                       |
| 391 |   1015.406126 |    611.462284 | Steven Traver                                                                                                                                                                   |
| 392 |    593.032221 |    563.525299 | Oscar Sanisidro                                                                                                                                                                 |
| 393 |    796.110487 |     92.204146 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 394 |     75.827808 |    306.779840 | Kamil S. Jaron                                                                                                                                                                  |
| 395 |    716.311445 |    618.258764 | L. Shyamal                                                                                                                                                                      |
| 396 |    538.874447 |    245.637800 | Zimices                                                                                                                                                                         |
| 397 |    182.523095 |     80.472213 | NA                                                                                                                                                                              |
| 398 |    446.170497 |    573.901578 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                              |
| 399 |    215.685136 |    727.834128 | Jagged Fang Designs                                                                                                                                                             |
| 400 |      9.868496 |    165.929307 | Kamil S. Jaron                                                                                                                                                                  |
| 401 |    836.732993 |    453.753365 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 402 |    512.018832 |    776.559975 | Crystal Maier                                                                                                                                                                   |
| 403 |    463.928110 |    727.143589 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 404 |     18.245884 |    506.534742 | Jagged Fang Designs                                                                                                                                                             |
| 405 |    970.126607 |     23.673649 | Wayne Decatur                                                                                                                                                                   |
| 406 |    213.913013 |    119.319199 | Zimices                                                                                                                                                                         |
| 407 |    383.420366 |    300.592168 | Ferran Sayol                                                                                                                                                                    |
| 408 |    216.744042 |    764.482457 | B. Duygu Özpolat                                                                                                                                                                |
| 409 |    908.494062 |    520.945967 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 410 |     29.502449 |    490.604281 | NA                                                                                                                                                                              |
| 411 |    498.421177 |    593.309559 | Sarah Werning                                                                                                                                                                   |
| 412 |    904.274893 |    659.198377 | Meliponicultor Itaymbere                                                                                                                                                        |
| 413 |    274.620753 |      8.194378 | B. Duygu Özpolat                                                                                                                                                                |
| 414 |     87.197660 |    677.671017 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 415 |      9.590981 |    297.080472 | Kanako Bessho-Uehara                                                                                                                                                            |
| 416 |   1005.075982 |    590.380309 | Mason McNair                                                                                                                                                                    |
| 417 |    216.493632 |    618.458371 | Matt Crook                                                                                                                                                                      |
| 418 |    110.437594 |    254.693274 | NA                                                                                                                                                                              |
| 419 |     72.937728 |    372.308886 | NA                                                                                                                                                                              |
| 420 |    432.093665 |    588.396327 | Erika Schumacher                                                                                                                                                                |
| 421 |    633.482518 |    112.259342 | Gareth Monger                                                                                                                                                                   |
| 422 |    673.879416 |    706.269684 | Tracy A. Heath                                                                                                                                                                  |
| 423 |    784.785639 |     47.921877 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 424 |    119.160185 |    286.247327 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 425 |     12.518914 |    517.143704 | Matt Wilkins                                                                                                                                                                    |
| 426 |     56.259784 |    390.496574 | Sarah Werning                                                                                                                                                                   |
| 427 |    376.548551 |    465.201471 | Crystal Maier                                                                                                                                                                   |
| 428 |    654.978444 |    326.419916 | Inessa Voet                                                                                                                                                                     |
| 429 |    507.984380 |     11.133770 | S.Martini                                                                                                                                                                       |
| 430 |    560.202806 |    207.691950 | NA                                                                                                                                                                              |
| 431 |    706.685749 |    252.240018 | Emily Willoughby                                                                                                                                                                |
| 432 |    442.866706 |    656.529745 | Collin Gross                                                                                                                                                                    |
| 433 |    605.403500 |     25.841931 | Margot Michaud                                                                                                                                                                  |
| 434 |    466.873107 |    319.668982 | Zimices                                                                                                                                                                         |
| 435 |    385.873991 |    433.531431 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 436 |    106.534115 |     31.560974 | Gareth Monger                                                                                                                                                                   |
| 437 |    407.367208 |    546.042466 | Margot Michaud                                                                                                                                                                  |
| 438 |    890.995387 |    694.705858 | Trond R. Oskars                                                                                                                                                                 |
| 439 |    495.680964 |    382.112474 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 440 |    263.911287 |    305.483681 | Carlos Cano-Barbacil                                                                                                                                                            |
| 441 |    982.625834 |    277.033862 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 442 |    288.882276 |    418.687506 | Carlos Cano-Barbacil                                                                                                                                                            |
| 443 |     19.592826 |    577.312606 | NA                                                                                                                                                                              |
| 444 |    780.160779 |    695.948008 | T. Michael Keesey                                                                                                                                                               |
| 445 |     26.306761 |     28.079234 | Scott Hartman                                                                                                                                                                   |
| 446 |    829.518843 |    213.071921 | Matt Crook                                                                                                                                                                      |
| 447 |    275.856731 |    133.765327 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 448 |    575.226264 |    487.775477 | Michelle Site                                                                                                                                                                   |
| 449 |    408.905060 |    295.005533 | Maxime Dahirel                                                                                                                                                                  |
| 450 |    733.946292 |    154.680278 | Gareth Monger                                                                                                                                                                   |
| 451 |   1010.228521 |    358.419930 | Michael P. Taylor                                                                                                                                                               |
| 452 |    404.670908 |    176.794586 | T. Michael Keesey                                                                                                                                                               |
| 453 |    394.181641 |     73.664539 | nicubunu                                                                                                                                                                        |
| 454 |    694.667628 |    753.507621 | NA                                                                                                                                                                              |
| 455 |    764.830753 |    414.533383 | Steven Traver                                                                                                                                                                   |
| 456 |    638.605842 |     77.521417 | Chris huh                                                                                                                                                                       |
| 457 |    286.248860 |    274.372631 | Margot Michaud                                                                                                                                                                  |
| 458 |    207.316927 |    151.968615 | Matt Crook                                                                                                                                                                      |
| 459 |    626.624541 |    533.226247 | Henry Lydecker                                                                                                                                                                  |
| 460 |    663.432986 |    313.552668 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 461 |    488.962515 |    516.497706 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 462 |     79.599778 |     48.835609 | Scott Hartman                                                                                                                                                                   |
| 463 |    958.519154 |    547.627322 | Tasman Dixon                                                                                                                                                                    |
| 464 |     76.077449 |    750.108805 | Armin Reindl                                                                                                                                                                    |
| 465 |    172.912275 |    599.275110 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 466 |    823.574130 |    241.800263 | Ingo Braasch                                                                                                                                                                    |
| 467 |     94.346885 |    608.014635 | Matt Crook                                                                                                                                                                      |
| 468 |    628.125170 |    177.958531 | Andy Wilson                                                                                                                                                                     |
| 469 |    215.218526 |    745.232120 | Geoff Shaw                                                                                                                                                                      |
| 470 |    766.059830 |    741.936963 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 471 |    969.902645 |    688.404446 | Matt Crook                                                                                                                                                                      |
| 472 |     40.942855 |    793.696722 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 473 |    850.988611 |    374.055930 | Matt Crook                                                                                                                                                                      |
| 474 |    779.376718 |    631.211598 | FunkMonk                                                                                                                                                                        |
| 475 |    589.476651 |    159.881063 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 476 |    414.308270 |    366.517927 | T. Michael Keesey                                                                                                                                                               |
| 477 |    467.276168 |    360.980957 | Margot Michaud                                                                                                                                                                  |
| 478 |    492.176388 |    772.108894 | Matt Celeskey                                                                                                                                                                   |
| 479 |    127.099408 |    409.225972 | NA                                                                                                                                                                              |
| 480 |    205.333025 |    268.400723 | Verisimilus                                                                                                                                                                     |
| 481 |    792.591908 |     32.247480 | NASA                                                                                                                                                                            |
| 482 |    779.661277 |     33.214526 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                            |
| 483 |   1012.234813 |    427.039092 | Martin R. Smith                                                                                                                                                                 |
| 484 |    481.473509 |    716.229457 | Sarah Werning                                                                                                                                                                   |
| 485 |    109.733568 |    546.826637 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 486 |     33.297285 |    108.629155 | Carlos Cano-Barbacil                                                                                                                                                            |
| 487 |    382.829686 |    136.114388 | L. Shyamal                                                                                                                                                                      |
| 488 |    472.762472 |    526.480760 | Gareth Monger                                                                                                                                                                   |
| 489 |    819.686892 |    448.500971 | Margot Michaud                                                                                                                                                                  |
| 490 |    151.864185 |    549.139476 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 491 |    409.268818 |    699.572777 | NA                                                                                                                                                                              |
| 492 |    884.576604 |    208.596660 | Matt Crook                                                                                                                                                                      |
| 493 |    746.404004 |     39.951363 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                     |
| 494 |    486.618298 |    165.273290 | Markus A. Grohme                                                                                                                                                                |
| 495 |    318.332119 |    596.500733 | Raven Amos                                                                                                                                                                      |
| 496 |    118.751845 |    790.971507 | Margot Michaud                                                                                                                                                                  |
| 497 |    596.563024 |    400.080992 | Hugo Gruson                                                                                                                                                                     |
| 498 |     90.382269 |    743.069132 | Markus A. Grohme                                                                                                                                                                |
| 499 |    602.805426 |    500.501381 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 500 |     58.083727 |    489.208290 | Margot Michaud                                                                                                                                                                  |
| 501 |    273.845192 |    352.735352 | NA                                                                                                                                                                              |
| 502 |    184.110500 |    341.263306 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 503 |    414.547907 |    211.383225 | Gareth Monger                                                                                                                                                                   |
| 504 |    390.580574 |     84.247423 | Sarah Werning                                                                                                                                                                   |
| 505 |    132.256761 |    517.993475 | Matt Crook                                                                                                                                                                      |
| 506 |    705.743168 |    133.969944 | Christoph Schomburg                                                                                                                                                             |
| 507 |    462.590304 |    466.129180 | Smokeybjb                                                                                                                                                                       |
| 508 |    811.815767 |    307.882285 | Scott Hartman                                                                                                                                                                   |
| 509 |    486.715981 |    146.464712 | Steven Traver                                                                                                                                                                   |
| 510 |    350.360997 |    430.885492 | Lukasiniho                                                                                                                                                                      |
| 511 |    437.908898 |     50.117687 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 512 |    143.923729 |    203.829487 | M Kolmann                                                                                                                                                                       |
| 513 |    656.340130 |    563.403041 | Ingo Braasch                                                                                                                                                                    |
| 514 |    615.733728 |     75.907256 | NA                                                                                                                                                                              |
| 515 |    721.067814 |    596.026717 | Gareth Monger                                                                                                                                                                   |
| 516 |    823.673635 |    739.637400 | C. Abraczinskas                                                                                                                                                                 |
| 517 |    488.384523 |    469.594847 | Dmitry Bogdanov                                                                                                                                                                 |
| 518 |    264.173898 |    240.074753 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                             |
| 519 |    124.894179 |    382.788191 | Gareth Monger                                                                                                                                                                   |
| 520 |    300.086129 |      7.417701 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 521 |    245.916560 |     16.721901 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 522 |    232.591093 |    331.301144 | Ferran Sayol                                                                                                                                                                    |
| 523 |    937.248427 |    274.701578 | Zimices                                                                                                                                                                         |
| 524 |    635.038667 |    165.382023 | SauropodomorphMonarch                                                                                                                                                           |
| 525 |    631.867455 |    566.088510 | Margot Michaud                                                                                                                                                                  |
| 526 |    279.508642 |    143.290322 | Beth Reinke                                                                                                                                                                     |
| 527 |    583.061700 |    455.465727 | Anthony Caravaggi                                                                                                                                                               |
| 528 |    356.176168 |    167.871647 | Tauana J. Cunha                                                                                                                                                                 |
| 529 |    372.985188 |    515.547631 | Emily Willoughby                                                                                                                                                                |
| 530 |     79.782937 |      9.542651 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                 |
| 531 |    144.725007 |    661.675754 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                     |
| 532 |    127.280685 |     94.772586 | Ferran Sayol                                                                                                                                                                    |
| 533 |    447.412356 |    585.372583 | Hans Hillewaert                                                                                                                                                                 |
| 534 |    210.330892 |     16.484906 | Margot Michaud                                                                                                                                                                  |
| 535 |    308.316952 |    447.053062 | Gareth Monger                                                                                                                                                                   |
| 536 |    400.795870 |    617.509705 | Ferran Sayol                                                                                                                                                                    |
| 537 |    678.298785 |    650.093815 | Zimices                                                                                                                                                                         |
| 538 |    236.956141 |    176.870555 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 539 |    863.814076 |    183.549703 | Jaime Headden                                                                                                                                                                   |
| 540 |    515.213829 |    336.919643 | Kamil S. Jaron                                                                                                                                                                  |
| 541 |    337.234715 |     67.068568 | Zimices                                                                                                                                                                         |
| 542 |     20.549095 |    226.408104 | Jagged Fang Designs                                                                                                                                                             |
| 543 |    167.810362 |    458.807502 | NA                                                                                                                                                                              |
| 544 |    626.906289 |    642.460755 | NA                                                                                                                                                                              |
| 545 |    290.831937 |    229.525760 | Steven Traver                                                                                                                                                                   |
| 546 |    782.440774 |    748.182755 | T. Michael Keesey                                                                                                                                                               |
| 547 |    881.301883 |    343.605956 | SecretJellyMan                                                                                                                                                                  |
| 548 |    623.116485 |    410.970700 | Maija Karala                                                                                                                                                                    |
| 549 |    362.690211 |     82.171403 | Robert Hering                                                                                                                                                                   |
| 550 |    571.023177 |    505.159061 | Scott Hartman                                                                                                                                                                   |
| 551 |    870.504461 |    162.597673 | Gustav Mützel                                                                                                                                                                   |
| 552 |    576.917658 |     58.573206 | Joanna Wolfe                                                                                                                                                                    |
| 553 |    436.878549 |    748.568374 | Jagged Fang Designs                                                                                                                                                             |
| 554 |    842.264934 |    488.314770 | David Liao                                                                                                                                                                      |
| 555 |    991.104754 |    292.577109 | Ferran Sayol                                                                                                                                                                    |
| 556 |    259.466537 |    560.879814 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
| 557 |    896.103738 |    458.097254 | Riccardo Percudani                                                                                                                                                              |
| 558 |    873.613942 |    475.163070 | Steven Traver                                                                                                                                                                   |
| 559 |    416.050130 |    656.327694 | Emma Hughes                                                                                                                                                                     |
| 560 |    192.784842 |    286.887090 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 561 |    255.415228 |    351.486442 | Scott Hartman                                                                                                                                                                   |
| 562 |    868.571079 |    659.960300 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 563 |    258.218540 |    361.946809 | Markus A. Grohme                                                                                                                                                                |
| 564 |    700.221428 |    684.940072 | Lukasiniho                                                                                                                                                                      |
| 565 |    710.861235 |    548.973406 | Ben Liebeskind                                                                                                                                                                  |
| 566 |    888.244926 |    601.745764 | Beth Reinke                                                                                                                                                                     |
| 567 |    421.394743 |    533.863402 | Rebecca Groom                                                                                                                                                                   |
| 568 |    402.662495 |    407.481622 | Zimices                                                                                                                                                                         |
| 569 |    849.220592 |    660.640430 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 570 |     13.990203 |    627.864810 | Anthony Caravaggi                                                                                                                                                               |
| 571 |     64.582092 |    402.201329 | Zimices                                                                                                                                                                         |
| 572 |    674.391348 |    756.130731 | Matt Crook                                                                                                                                                                      |
| 573 |     53.130440 |    110.721919 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                               |
| 574 |      9.987879 |    535.259866 | Emily Willoughby                                                                                                                                                                |
| 575 |    850.400403 |    598.973828 | Steven Traver                                                                                                                                                                   |
| 576 |    758.672353 |     61.585757 | Qiang Ou                                                                                                                                                                        |
| 577 |   1010.554931 |    307.776303 | Lily Hughes                                                                                                                                                                     |
| 578 |    699.880636 |    634.531076 | Matt Crook                                                                                                                                                                      |
| 579 |    396.928516 |    116.842160 | NA                                                                                                                                                                              |
| 580 |    430.573030 |    387.722617 | Mathilde Cordellier                                                                                                                                                             |
| 581 |    565.709261 |     82.996045 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 582 |    171.147289 |     11.338781 | Erika Schumacher                                                                                                                                                                |
| 583 |    483.994624 |     11.931837 | Gareth Monger                                                                                                                                                                   |
| 584 |    400.258861 |    348.418335 | NA                                                                                                                                                                              |
| 585 |     17.061161 |     59.196150 | Zimices                                                                                                                                                                         |
| 586 |    931.773350 |    543.605205 | Margot Michaud                                                                                                                                                                  |
| 587 |    726.260395 |    375.306916 | Michael Scroggie                                                                                                                                                                |
| 588 |    493.610853 |    664.265985 | Ferran Sayol                                                                                                                                                                    |
| 589 |    240.391355 |     84.570915 | Christine Axon                                                                                                                                                                  |
| 590 |    463.713891 |     42.863972 | Peileppe                                                                                                                                                                        |
| 591 |     55.718999 |    671.125839 | L. Shyamal                                                                                                                                                                      |
| 592 |    634.606115 |    219.911264 | Emily Willoughby                                                                                                                                                                |
| 593 |    991.974227 |      8.106440 | Steven Traver                                                                                                                                                                   |
| 594 |   1008.487352 |    188.706261 | Zimices                                                                                                                                                                         |
| 595 |    863.668355 |    572.888914 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                   |
| 596 |    189.251944 |    446.292240 | Owen Jones                                                                                                                                                                      |
| 597 |    296.978835 |     86.251204 | Maxime Dahirel                                                                                                                                                                  |
| 598 |    293.677602 |     61.960340 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 599 |    867.614948 |      5.506637 | Jack Mayer Wood                                                                                                                                                                 |
| 600 |     83.332285 |    391.540795 | Armin Reindl                                                                                                                                                                    |
| 601 |    673.467675 |    689.484909 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                  |
| 602 |    267.262972 |    200.118538 | Ferran Sayol                                                                                                                                                                    |
| 603 |    391.117463 |    675.949479 | FunkMonk                                                                                                                                                                        |
| 604 |     98.864015 |    312.771537 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 605 |    562.531266 |    223.128323 | NA                                                                                                                                                                              |
| 606 |     34.404621 |    350.257415 | Zimices                                                                                                                                                                         |
| 607 |    979.896244 |    716.437208 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 608 |    781.215445 |    580.720144 | Steven Traver                                                                                                                                                                   |
| 609 |    455.032443 |    121.549253 | Ingo Braasch                                                                                                                                                                    |
| 610 |    907.579815 |    438.888113 | Steven Traver                                                                                                                                                                   |
| 611 |    779.834414 |    557.064765 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                           |
| 612 |    698.718185 |    243.506038 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                |
| 613 |    544.269917 |     53.610456 | Zimices                                                                                                                                                                         |
| 614 |    736.080077 |    251.446036 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                       |
| 615 |    174.475006 |    251.358597 | Zimices                                                                                                                                                                         |
| 616 |    278.275620 |    688.168671 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                     |
| 617 |    802.365611 |    531.978445 | Gareth Monger                                                                                                                                                                   |
| 618 |    637.957052 |    500.638233 | Harold N Eyster                                                                                                                                                                 |
| 619 |    850.786224 |    403.161924 | (after Spotila 2004)                                                                                                                                                            |
| 620 |    551.966170 |    667.090281 | Margot Michaud                                                                                                                                                                  |
| 621 |    437.042115 |    520.062139 | Ferran Sayol                                                                                                                                                                    |
| 622 |    823.833379 |    758.771568 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 623 |    826.978764 |     17.355212 | Steven Traver                                                                                                                                                                   |
| 624 |     57.300233 |    101.298298 | NA                                                                                                                                                                              |
| 625 |      8.962973 |    358.952089 | Melissa Broussard                                                                                                                                                               |
| 626 |    128.291464 |      7.752252 | Scott Hartman                                                                                                                                                                   |
| 627 |    864.335895 |    562.111002 | Matt Dempsey                                                                                                                                                                    |
| 628 |    271.539095 |    725.424677 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 629 |    480.259485 |    558.815255 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                        |
| 630 |    198.084654 |    310.070725 | Margot Michaud                                                                                                                                                                  |
| 631 |    175.735164 |     62.532535 | NA                                                                                                                                                                              |
| 632 |     36.816074 |    784.238597 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                        |
| 633 |    496.914279 |    251.776574 | Dean Schnabel                                                                                                                                                                   |
| 634 |    806.077137 |    788.709732 | Christoph Schomburg                                                                                                                                                             |
| 635 |   1004.293091 |     61.081705 | Xavier Giroux-Bougard                                                                                                                                                           |
| 636 |    428.067279 |    105.516324 | Ferran Sayol                                                                                                                                                                    |
| 637 |    755.341169 |    792.664125 | Markus A. Grohme                                                                                                                                                                |
| 638 |    307.821738 |    734.952788 | Smokeybjb                                                                                                                                                                       |
| 639 |    370.944701 |    732.646130 | NA                                                                                                                                                                              |
| 640 |    217.100732 |    296.076800 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                        |
| 641 |    532.690179 |    773.834205 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 642 |    462.898894 |    594.591858 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 643 |    988.707139 |    782.947158 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                  |
| 644 |    487.904650 |     64.243307 | Jagged Fang Designs                                                                                                                                                             |
| 645 |    948.969501 |    591.152247 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                           |
| 646 |    576.341109 |    355.418574 | CNZdenek                                                                                                                                                                        |
| 647 |   1010.668176 |    326.488745 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 648 |    680.139934 |    674.717072 | FunkMonk                                                                                                                                                                        |
| 649 |    599.864799 |    757.784009 | Matt Crook                                                                                                                                                                      |
| 650 |    389.295386 |    705.421808 | Matt Crook                                                                                                                                                                      |
| 651 |     15.874272 |     17.498189 | JCGiron                                                                                                                                                                         |
| 652 |    808.810516 |    451.704998 | Steven Traver                                                                                                                                                                   |
| 653 |    384.900348 |    449.516355 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 654 |    133.988527 |    372.700869 | NA                                                                                                                                                                              |
| 655 |     15.151477 |    215.010829 | David Orr                                                                                                                                                                       |
| 656 |    647.989889 |    513.236975 | NA                                                                                                                                                                              |
| 657 |    450.376163 |    168.507140 | Jimmy Bernot                                                                                                                                                                    |
| 658 |    444.121107 |     13.024195 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 659 |     16.409662 |    372.622842 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                        |
| 660 |    805.875717 |    409.962072 | NA                                                                                                                                                                              |
| 661 |    457.975550 |    395.828158 | Rebecca Groom                                                                                                                                                                   |
| 662 |    170.788549 |    264.246225 | Zimices                                                                                                                                                                         |
| 663 |    517.787487 |    707.565613 | Mette Aumala                                                                                                                                                                    |
| 664 |    917.841273 |    210.722522 | Andy Wilson                                                                                                                                                                     |
| 665 |    837.363617 |    171.612367 | NA                                                                                                                                                                              |
| 666 |    826.756893 |    526.726631 | Chuanixn Yu                                                                                                                                                                     |
| 667 |    307.342352 |    481.881897 | Kamil S. Jaron                                                                                                                                                                  |
| 668 |    464.595087 |    667.479074 | Yan Wong                                                                                                                                                                        |
| 669 |    495.742229 |    342.572810 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                               |
| 670 |    280.698763 |    430.407308 | White Wolf                                                                                                                                                                      |
| 671 |    767.490675 |    481.526186 | Jagged Fang Designs                                                                                                                                                             |
| 672 |    846.221301 |    676.567812 | T. Michael Keesey                                                                                                                                                               |
| 673 |    244.356557 |    312.511055 | Ferran Sayol                                                                                                                                                                    |
| 674 |     27.082656 |    690.570230 | Steven Traver                                                                                                                                                                   |
| 675 |    206.098078 |    133.863798 | xgirouxb                                                                                                                                                                        |
| 676 |    761.065537 |    478.053852 | Gareth Monger                                                                                                                                                                   |
| 677 |    808.232106 |    609.448560 | Steven Traver                                                                                                                                                                   |
| 678 |    879.606221 |    498.157931 | Zimices                                                                                                                                                                         |
| 679 |    129.509022 |    315.264521 | Zimices                                                                                                                                                                         |
| 680 |    747.965045 |    752.638107 | Sarah Werning                                                                                                                                                                   |
| 681 |    247.518618 |     10.096444 | NA                                                                                                                                                                              |
| 682 |    492.773520 |     58.086006 | Erika Schumacher                                                                                                                                                                |
| 683 |    783.764362 |    754.371013 | Juan Carlos Jerí                                                                                                                                                                |
| 684 |     49.041460 |    680.869954 | Maija Karala                                                                                                                                                                    |
| 685 |     23.700550 |    545.661755 | Matt Crook                                                                                                                                                                      |
| 686 |    423.434020 |    621.220483 | Kai R. Caspar                                                                                                                                                                   |
| 687 |     68.389684 |    686.805954 | Zimices                                                                                                                                                                         |
| 688 |    831.706054 |    653.935196 | Matt Crook                                                                                                                                                                      |
| 689 |      8.643053 |     80.718024 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 690 |    188.498749 |    679.394018 | Matt Crook                                                                                                                                                                      |
| 691 |    280.920389 |    747.787767 | Gabriel Lio, vectorized by Zimices                                                                                                                                              |
| 692 |    734.204525 |    174.545714 | Beth Reinke                                                                                                                                                                     |
| 693 |     44.687192 |    179.317177 | Caleb M. Gordon                                                                                                                                                                 |
| 694 |    553.841497 |     72.784240 | Matt Crook                                                                                                                                                                      |
| 695 |    267.287527 |    215.430458 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                        |
| 696 |    662.617308 |    261.393686 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 697 |    413.689985 |    120.123214 | Fernando Carezzano                                                                                                                                                              |
| 698 |    978.576441 |    135.713778 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 699 |    445.811991 |    223.587568 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 700 |    557.122194 |    273.199956 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 701 |      9.035332 |    285.892297 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 702 |    583.031829 |    382.653977 | Ingo Braasch                                                                                                                                                                    |
| 703 |    361.406137 |    388.182684 | Jagged Fang Designs                                                                                                                                                             |
| 704 |    609.058097 |     46.331655 | Lily Hughes                                                                                                                                                                     |
| 705 |    196.863604 |    789.276390 | NA                                                                                                                                                                              |
| 706 |    794.866753 |    475.976706 | Harold N Eyster                                                                                                                                                                 |
| 707 |    840.196979 |    322.570729 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                     |
| 708 |    947.802350 |     10.172834 | Steven Traver                                                                                                                                                                   |
| 709 |    576.046278 |    658.099486 | Kamil S. Jaron                                                                                                                                                                  |
| 710 |    556.030842 |    265.115810 | Vanessa Guerra                                                                                                                                                                  |
| 711 |    951.890952 |    774.216829 | Scott Hartman                                                                                                                                                                   |
| 712 |    703.448080 |    790.267248 | FunkMonk                                                                                                                                                                        |
| 713 |    761.221526 |    429.794861 | Matt Crook                                                                                                                                                                      |
| 714 |    413.114259 |    200.291836 | T. Michael Keesey                                                                                                                                                               |
| 715 |    851.322281 |    772.013184 | Amanda Katzer                                                                                                                                                                   |
| 716 |    735.700078 |    651.325937 | Zimices                                                                                                                                                                         |
| 717 |    357.256724 |    535.193210 | David Orr                                                                                                                                                                       |
| 718 |   1001.775909 |     36.580843 | Roberto Diaz Sibaja, based on Domser                                                                                                                                            |
| 719 |    517.531819 |    227.119978 | Roberto Díaz Sibaja                                                                                                                                                             |
| 720 |    764.671842 |    783.816679 | Zimices                                                                                                                                                                         |
| 721 |    554.770741 |    475.266238 | Matt Crook                                                                                                                                                                      |
| 722 |    257.571746 |    564.662300 | Smokeybjb (modified by Mike Keesey)                                                                                                                                             |
| 723 |    540.501183 |    230.936680 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 724 |    205.263662 |    583.883924 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 725 |    500.937170 |    327.211111 | Margot Michaud                                                                                                                                                                  |
| 726 |    108.988690 |    773.169074 | Zimices                                                                                                                                                                         |
| 727 |    620.531136 |    308.840265 | Alexandre Vong                                                                                                                                                                  |
| 728 |    467.231703 |    583.688594 | Sean McCann                                                                                                                                                                     |
| 729 |    378.683653 |    632.416604 | Gareth Monger                                                                                                                                                                   |
| 730 |    667.724680 |    246.190246 | Chris huh                                                                                                                                                                       |
| 731 |    673.527631 |    427.821164 | Christoph Schomburg                                                                                                                                                             |
| 732 |    992.021451 |    592.880473 | Michelle Site                                                                                                                                                                   |
| 733 |    963.000547 |    737.359830 | Sean McCann                                                                                                                                                                     |
| 734 |    109.198656 |     69.238510 | Manabu Bessho-Uehara                                                                                                                                                            |
| 735 |    820.898949 |    626.686573 | Julio Garza                                                                                                                                                                     |
| 736 |     76.006825 |    427.539670 | Mariana Ruiz Villarreal                                                                                                                                                         |
| 737 |    209.181898 |    370.071195 | Dave Angelini                                                                                                                                                                   |
| 738 |    303.435222 |    304.721152 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 739 |    143.310775 |    593.741662 | Margot Michaud                                                                                                                                                                  |
| 740 |    739.334376 |    539.945846 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                |
| 741 |    734.664677 |    213.744278 | NA                                                                                                                                                                              |
| 742 |    641.824150 |    552.463127 | Andy Wilson                                                                                                                                                                     |
| 743 |    321.852078 |    164.157445 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                  |
| 744 |   1012.033029 |     74.662582 | Taro Maeda                                                                                                                                                                      |
| 745 |    134.971912 |     43.966324 | Matt Crook                                                                                                                                                                      |
| 746 |     10.459440 |    609.340164 | Gareth Monger                                                                                                                                                                   |
| 747 |    142.914745 |    638.790987 | NA                                                                                                                                                                              |
| 748 |     27.550372 |    211.413146 | Matt Crook                                                                                                                                                                      |
| 749 |    215.009556 |    676.539923 | NA                                                                                                                                                                              |
| 750 |     17.768175 |    710.242614 | G. M. Woodward                                                                                                                                                                  |
| 751 |    567.773225 |    540.246179 | Steven Traver                                                                                                                                                                   |
| 752 |    455.991405 |    649.263661 | Yan Wong                                                                                                                                                                        |
| 753 |    838.381781 |    440.786373 | Margot Michaud                                                                                                                                                                  |
| 754 |    348.074633 |    594.838440 | Jaime Headden                                                                                                                                                                   |
| 755 |    622.922432 |     51.095522 | Matt Crook                                                                                                                                                                      |
| 756 |    799.381166 |    686.908314 | Birgit Lang                                                                                                                                                                     |
| 757 |    133.908597 |    297.521801 | T. Michael Keesey                                                                                                                                                               |
| 758 |    637.851802 |      9.117591 | Joanna Wolfe                                                                                                                                                                    |
| 759 |     36.562399 |    186.161818 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 760 |    879.129671 |    579.778486 | Robert Gay                                                                                                                                                                      |
| 761 |    806.601869 |    131.910662 | Michael Scroggie                                                                                                                                                                |
| 762 |    636.326381 |    103.186322 | Jimmy Bernot                                                                                                                                                                    |
| 763 |    741.502676 |    168.053644 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                               |
| 764 |    338.274026 |    432.221676 | Andy Wilson                                                                                                                                                                     |
| 765 |    285.537258 |    606.231017 | T. Michael Keesey                                                                                                                                                               |
| 766 |    889.809453 |     94.805406 | Steven Traver                                                                                                                                                                   |
| 767 |    874.589669 |    265.819576 | Martin Kevil                                                                                                                                                                    |
| 768 |    641.737585 |    486.140648 | Ieuan Jones                                                                                                                                                                     |
| 769 |     73.831240 |    600.463930 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 770 |    341.642345 |    305.933201 | Margot Michaud                                                                                                                                                                  |
| 771 |    630.216190 |    245.142240 | Blair Perry                                                                                                                                                                     |
| 772 |    271.517543 |    437.561629 | Ingo Braasch                                                                                                                                                                    |
| 773 |    547.255578 |    758.054754 | Becky Barnes                                                                                                                                                                    |
| 774 |    118.665590 |    517.587161 | Matt Crook                                                                                                                                                                      |
| 775 |    764.186987 |    444.516421 | Gareth Monger                                                                                                                                                                   |
| 776 |   1014.569996 |    638.105187 | NA                                                                                                                                                                              |
| 777 |    924.227201 |     17.170301 | Michael Scroggie                                                                                                                                                                |
| 778 |    484.964214 |    742.051733 | Jakovche                                                                                                                                                                        |
| 779 |    166.289812 |     44.378408 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                                   |
| 780 |     42.767355 |    526.269124 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 781 |    726.003209 |    285.175329 | Ferran Sayol                                                                                                                                                                    |
| 782 |    927.473173 |    254.901614 | Mo Hassan                                                                                                                                                                       |
| 783 |     32.763126 |    198.099360 | Ingo Braasch                                                                                                                                                                    |
| 784 |    144.041907 |     66.890503 | Tod Robbins                                                                                                                                                                     |
| 785 |    372.466885 |    485.306942 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 786 |    512.330034 |    760.758727 | Scott Hartman                                                                                                                                                                   |
| 787 |    391.700246 |    661.905816 | Christoph Schomburg                                                                                                                                                             |
| 788 |   1016.387120 |    682.951176 | S.Martini                                                                                                                                                                       |
| 789 |    993.441741 |    304.111467 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 790 |    651.715217 |    679.526968 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 791 |    895.712213 |    544.466459 | Christoph Schomburg                                                                                                                                                             |
| 792 |    999.984057 |    390.749656 | Zimices                                                                                                                                                                         |
| 793 |    952.082289 |    535.257768 | Margot Michaud                                                                                                                                                                  |
| 794 |    671.032943 |    764.516102 | Tasman Dixon                                                                                                                                                                    |
| 795 |    831.743130 |    776.826882 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 796 |     23.782672 |    753.409267 | Steven Traver                                                                                                                                                                   |
| 797 |    145.602821 |    294.539825 | Scott Hartman                                                                                                                                                                   |
| 798 |    142.608705 |    300.552979 | Chris huh                                                                                                                                                                       |
| 799 |    477.985343 |    258.212868 | Crystal Maier                                                                                                                                                                   |
| 800 |    923.696345 |    531.194864 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 801 |     33.904901 |    276.444709 | T. Michael Keesey                                                                                                                                                               |
| 802 |    619.302861 |    292.589944 | Matt Crook                                                                                                                                                                      |
| 803 |    450.168713 |    632.029108 | Courtney Rockenbach                                                                                                                                                             |
| 804 |    707.804349 |    374.309587 | NA                                                                                                                                                                              |
| 805 |    737.720439 |    600.800355 | Steven Traver                                                                                                                                                                   |
| 806 |    477.307292 |    288.786412 | Felix Vaux                                                                                                                                                                      |
| 807 |    959.521917 |    372.240789 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 808 |    421.011596 |    512.209097 | Jimmy Bernot                                                                                                                                                                    |
| 809 |    248.609631 |    567.958633 | T. Michael Keesey                                                                                                                                                               |
| 810 |    882.980635 |    539.877851 | T. Michael Keesey                                                                                                                                                               |
| 811 |    289.441154 |    539.534915 | Benjamint444                                                                                                                                                                    |
| 812 |    794.954682 |    129.089048 | L. Shyamal                                                                                                                                                                      |
| 813 |    248.231575 |    252.395627 | Tasman Dixon                                                                                                                                                                    |
| 814 |    214.050240 |    306.509928 | Julio Garza                                                                                                                                                                     |
| 815 |    259.201700 |    313.555063 | Chase Brownstein                                                                                                                                                                |
| 816 |    232.359513 |    296.014761 | Armin Reindl                                                                                                                                                                    |
| 817 |     44.672846 |    139.942233 | NA                                                                                                                                                                              |
| 818 |     85.081569 |    220.263660 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 819 |    455.149797 |    620.406628 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 820 |     21.172991 |    144.886936 | Scott Hartman                                                                                                                                                                   |
| 821 |    861.957908 |    794.907969 | Zimices                                                                                                                                                                         |
| 822 |    563.895609 |    685.751580 | Erika Schumacher                                                                                                                                                                |
| 823 |    936.242562 |    604.798733 | Margot Michaud                                                                                                                                                                  |
| 824 |    693.842076 |    653.678772 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 825 |    217.631800 |    734.734555 | S.Martini                                                                                                                                                                       |
| 826 |    406.976309 |    640.838984 | Carlos Cano-Barbacil                                                                                                                                                            |
| 827 |    377.988460 |    413.007623 | Steven Traver                                                                                                                                                                   |
| 828 |    135.142840 |    554.251182 | T. Michael Keesey                                                                                                                                                               |
| 829 |    513.462384 |    574.021085 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 830 |    613.558019 |    631.265100 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                            |
| 831 |    215.028585 |      7.132174 | Margot Michaud                                                                                                                                                                  |
| 832 |     56.886342 |    741.151041 | Gareth Monger                                                                                                                                                                   |
| 833 |    741.083702 |    142.469891 | Steven Traver                                                                                                                                                                   |
| 834 |    648.710215 |    252.116137 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 835 |   1009.078405 |    438.052874 | Chris huh                                                                                                                                                                       |
| 836 |    985.326966 |    119.025814 | Amanda Katzer                                                                                                                                                                   |
| 837 |     27.854844 |    386.329686 | NA                                                                                                                                                                              |
| 838 |   1000.640019 |    683.467131 | Matt Crook                                                                                                                                                                      |
| 839 |     51.320195 |     52.119753 | Iain Reid                                                                                                                                                                       |
| 840 |    165.034796 |    791.163331 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                               |
| 841 |    898.742980 |    255.122938 | Matt Crook                                                                                                                                                                      |
| 842 |    428.691924 |    720.593969 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 843 |    186.466835 |     30.249550 | M. A. Broussard                                                                                                                                                                 |
| 844 |    385.021695 |    470.231910 | NA                                                                                                                                                                              |
| 845 |    983.802100 |     53.222007 | Harold N Eyster                                                                                                                                                                 |
| 846 |    624.883078 |    545.495559 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 847 |    994.616301 |     27.260033 | Kai R. Caspar                                                                                                                                                                   |
| 848 |     74.858663 |    762.911768 | Kai R. Caspar                                                                                                                                                                   |
| 849 |    904.379292 |    642.070720 | Zimices                                                                                                                                                                         |
| 850 |    717.217592 |    149.786348 | G. M. Woodward                                                                                                                                                                  |
| 851 |    561.672582 |     59.129230 | Michelle Site                                                                                                                                                                   |
| 852 |    510.755758 |    135.366498 | Mo Hassan                                                                                                                                                                       |
| 853 |    994.284143 |    797.756440 | Scott Hartman                                                                                                                                                                   |
| 854 |    236.018974 |    565.117420 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                          |
| 855 |    323.078847 |    346.642157 | Scott Hartman                                                                                                                                                                   |
| 856 |    576.704712 |    565.690106 | Dmitry Bogdanov                                                                                                                                                                 |
| 857 |    477.219132 |    612.350091 | Mathew Wedel                                                                                                                                                                    |
| 858 |   1013.490459 |    179.486209 | Steven Traver                                                                                                                                                                   |
| 859 |    261.128718 |    188.806190 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 860 |   1009.913567 |    107.897548 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 861 |    125.409270 |     25.781899 | Matt Crook                                                                                                                                                                      |
| 862 |    132.671611 |    757.595786 | Ferran Sayol                                                                                                                                                                    |
| 863 |    902.020236 |    203.082617 | Iain Reid                                                                                                                                                                       |
| 864 |    773.686040 |     87.109827 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                  |
| 865 |    233.160657 |    306.142227 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                       |
| 866 |    862.862808 |    210.493821 | Michael P. Taylor                                                                                                                                                               |
| 867 |    497.847540 |    532.853141 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 868 |     10.666806 |    670.960037 | Maxime Dahirel                                                                                                                                                                  |
| 869 |    731.509642 |    159.873406 | Javiera Constanzo                                                                                                                                                               |
| 870 |    955.606971 |    564.787682 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                          |
| 871 |     18.863228 |    339.183411 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                              |
| 872 |    100.379390 |    247.648794 | Kamil S. Jaron                                                                                                                                                                  |
| 873 |    729.708212 |    113.310851 | Matt Crook                                                                                                                                                                      |
| 874 |     91.683774 |    300.591734 | Matt Crook                                                                                                                                                                      |
| 875 |    405.750577 |    707.291537 | Gareth Monger                                                                                                                                                                   |
| 876 |    671.312312 |    745.480284 | T. Michael Keesey                                                                                                                                                               |
| 877 |    937.258956 |    514.193872 | Kamil S. Jaron                                                                                                                                                                  |
| 878 |    571.256798 |    599.550398 | Collin Gross                                                                                                                                                                    |
| 879 |    432.387624 |     59.619231 | T. Michael Keesey                                                                                                                                                               |
| 880 |    993.627412 |    767.361675 | Harold N Eyster                                                                                                                                                                 |
| 881 |    714.092465 |    213.258608 | T. Michael Keesey (after Mivart)                                                                                                                                                |
| 882 |    816.626413 |    710.861891 | Mathew Wedel                                                                                                                                                                    |
| 883 |    775.346523 |    722.412241 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                           |
| 884 |    748.510618 |    491.850389 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                  |
| 885 |    888.253883 |    647.223609 | NA                                                                                                                                                                              |
| 886 |    946.914566 |    754.605261 | Matt Crook                                                                                                                                                                      |
| 887 |    878.837747 |    181.958625 | Tasman Dixon                                                                                                                                                                    |
| 888 |    767.267724 |    192.975258 | Zimices                                                                                                                                                                         |
| 889 |     45.688191 |    433.916658 | Cesar Julian                                                                                                                                                                    |
| 890 |    954.499594 |    705.044841 | Dean Schnabel                                                                                                                                                                   |
| 891 |    263.699009 |    573.764219 | Mattia Menchetti                                                                                                                                                                |
| 892 |     60.568041 |    206.481077 | NA                                                                                                                                                                              |
| 893 |    930.480106 |    789.776386 | Kamil S. Jaron                                                                                                                                                                  |
| 894 |    351.994665 |     69.250621 | Sharon Wegner-Larsen                                                                                                                                                            |
| 895 |    632.504780 |    364.947723 | Noah Schlottman                                                                                                                                                                 |
| 896 |    209.811253 |    429.148016 | Steven Traver                                                                                                                                                                   |
| 897 |    926.732975 |    366.448982 | NA                                                                                                                                                                              |
| 898 |    516.687472 |    294.106599 | Michael Scroggie                                                                                                                                                                |
| 899 |    352.135385 |    404.681236 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                                     |
| 900 |    513.376037 |     78.802360 | Maija Karala                                                                                                                                                                    |
| 901 |   1000.574688 |    426.682756 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                       |
| 902 |    234.912349 |    666.791438 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 903 |    738.569628 |    447.895847 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 904 |    740.825963 |     22.111209 | T. Michael Keesey                                                                                                                                                               |
| 905 |    254.033218 |    343.203597 | Matt Crook                                                                                                                                                                      |
| 906 |    561.530925 |    155.005830 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                             |
| 907 |    149.030673 |    314.924976 | Neil Kelley                                                                                                                                                                     |
| 908 |    233.907377 |    128.469550 | Carlos Cano-Barbacil                                                                                                                                                            |
| 909 |    253.088073 |    229.357129 | Markus A. Grohme                                                                                                                                                                |
| 910 |    399.670066 |    786.160688 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 911 |    690.582093 |    229.030103 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                   |
| 912 |     42.497030 |    122.318999 | SauropodomorphMonarch                                                                                                                                                           |
| 913 |   1000.867789 |    101.382459 | Michael P. Taylor                                                                                                                                                               |
| 914 |    275.579902 |     28.833527 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 915 |    953.888900 |    609.112015 | Jagged Fang Designs                                                                                                                                                             |
| 916 |    203.844775 |    717.908488 | Steven Traver                                                                                                                                                                   |
| 917 |     18.191805 |    349.421553 | Zimices                                                                                                                                                                         |
| 918 |     23.790941 |    523.527051 | Renato Santos                                                                                                                                                                   |
| 919 |    663.203069 |    617.461478 | T. Michael Keesey                                                                                                                                                               |
| 920 |    971.330733 |    586.485720 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                          |
| 921 |    166.342325 |    547.478954 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |

    #> Your tweet has been posted!
