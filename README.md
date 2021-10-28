
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

Ferran Sayol, Lani Mohan, Archaeodontosaurus (vectorized by T. Michael
Keesey), T. Michael Keesey (from a mount by Allis Markham), Henry
Fairfield Osborn, vectorized by Zimices, Chris huh, T. Michael Keesey,
Scott Reid, Jagged Fang Designs, zoosnow, Kamil S. Jaron, Michelle Site,
Alexander Schmidt-Lebuhn, Steven Traver, Alex Slavenko, Zimices, Scott
Hartman, Matt Crook, Dean Schnabel, Dori <dori@merr.info> (source photo)
and Nevit Dilmen, Margot Michaud, Martin R. Smith, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Catherine Yasuda, Benjamint444, C. Camilo Julián-Caballero,
Gareth Monger, Carlos Cano-Barbacil, Ville Koistinen (vectorized by T.
Michael Keesey), Rebecca Groom, Chloé Schmidt, Yan Wong from drawing by
Joseph Smit, Dmitry Bogdanov (vectorized by T. Michael Keesey), Matt
Martyniuk, Nobu Tamura (vectorized by T. Michael Keesey), Birgit Lang,
T. Michael Keesey (vectorization) and Larry Loos (photography), Peter
Coxhead, Ernst Haeckel (vectorized by T. Michael Keesey), Mathew Wedel,
Maxwell Lefroy (vectorized by T. Michael Keesey), Harold N Eyster,
Manabu Sakamoto, Yan Wong, DW Bapst (modified from Bulman, 1970),
Heinrich Harder (vectorized by T. Michael Keesey), Matt Dempsey, Dmitry
Bogdanov, Young and Zhao (1972:figure 4), modified by Michael P. Taylor,
Roberto Díaz Sibaja, Tauana J. Cunha, Maija Karala, Mathilde Cordellier,
Emily Willoughby, Emma Kissling, Christopher Watson (photo) and T.
Michael Keesey (vectorization), Gopal Murali, Jose Carlos Arenas-Monroy,
David Orr, Rene Martin, Eduard Solà Vázquez, vectorised by Yan Wong,
Andrew A. Farke, modified from original by H. Milne Edwards, Lindberg
(vectorized by T. Michael Keesey), Lukasiniho, TaraTaylorDesign, Renata
F. Martins, Mark Hofstetter (vectorized by T. Michael Keesey), Katie S.
Collins, Sharon Wegner-Larsen, Robert Gay, Andrew A. Farke, Cyril
Matthey-Doret, adapted from Bernard Chaubet, CNZdenek, Qiang Ou, Mali’o
Kodis, image from the Biodiversity Heritage Library, Blair Perry,
Shyamal, Jerry Oldenettel (vectorized by T. Michael Keesey), Stanton F.
Fink (vectorized by T. Michael Keesey), Christine Axon, Nina Skinner,
Gregor Bucher, Max Farnworth, Ludwik Gasiorowski, Obsidian Soul
(vectorized by T. Michael Keesey),
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Luis Cunha, Armelle Ansart
(photograph), Maxime Dahirel (digitisation), Collin Gross, Julio Garza,
Jonathan Wells, Jakovche, Oliver Griffith, Beth Reinke, Tasman Dixon,
Mali’o Kodis, image from the Smithsonian Institution, T. Michael Keesey
(photo by J. M. Garg), Francesco Veronesi (vectorized by T. Michael
Keesey), Joanna Wolfe, (after Spotila 2004), Blanco et al., 2014,
vectorized by Zimices, Michael P. Taylor, Joris van der Ham (vectorized
by T. Michael Keesey), Xavier Giroux-Bougard, Gabriela Palomo-Munoz,
Kimberly Haddrell, Conty (vectorized by T. Michael Keesey), Jan Sevcik
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T.
Michael Keesey), Original drawing by Nobu Tamura, vectorized by Roberto
Díaz Sibaja, Matthew E. Clapham, kreidefossilien.de, Darren Naish
(vectorize by T. Michael Keesey), Matus Valach, T. Michael Keesey (after
C. De Muizon), Sarah Alewijnse, Maxime Dahirel, François Michonneau,
Melissa Broussard, SauropodomorphMonarch, Caleb M. Brown, Birgit Lang;
original image by virmisco.org, Neil Kelley, Kent Elson Sorgon, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey (after MPF), FunkMonk, Nobu
Tamura, vectorized by Zimices, Tracy A. Heath, Martin R. Smith, after
Skovsted et al 2015, Cristopher Silva, Robert Bruce Horsfall, from W.B.
Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”, John
Gould (vectorized by T. Michael Keesey), Hans Hillewaert, Sarah Werning,
Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Almandine (vectorized by T. Michael Keesey), MPF (vectorized
by T. Michael Keesey), Mykle Hoban, Matt Martyniuk (vectorized by T.
Michael Keesey), Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Sergio A.
Muñoz-Gómez, U.S. Fish and Wildlife Service (illustration) and Timothy
J. Bartley (silhouette), Mateus Zica (modified by T. Michael Keesey),
Christoph Schomburg, Hans Hillewaert (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Nobu Tamura and
T. Michael Keesey, Noah Schlottman, photo from Casey Dunn, Robbie N.
Cada (vectorized by T. Michael Keesey), Steven Coombs, B. Duygu Özpolat,
Smokeybjb, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Oliver Voigt, Conty, Pete Buchholz, Cesar Julian,
Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette), Ville
Koistinen and T. Michael Keesey, Nicholas J. Czaplewski, vectorized by
Zimices, Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Felix
Vaux, Tony Ayling (vectorized by T. Michael Keesey), Tony Ayling, James
I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel,
and Jelle P. Wiersma (vectorized by T. Michael Keesey), T. Michael
Keesey (after Marek Velechovský), Ingo Braasch, Julia B McHugh,
LeonardoG (photography) and T. Michael Keesey (vectorization), Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Ekaterina Kopeykina (vectorized
by T. Michael Keesey), Terpsichores, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Mathieu
Basille, New York Zoological Society, Tambja (vectorized by T. Michael
Keesey), kotik, Richard Lampitt, Jeremy Young / NHM (vectorization by
Yan Wong), Zachary Quigley, Frank Denota, Lauren Anderson, Kai R.
Caspar, Chris Jennings (Risiatto), Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Keith
Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Tyler Greenfield and Dean Schnabel, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Nobu Tamura (modified by T. Michael Keesey), Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Joedison Rocha, Sibi (vectorized by
T. Michael Keesey), T. Michael Keesey (from a photo by Maximilian
Paradiz), Joe Schneid (vectorized by T. Michael Keesey), Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Javier Luque, Michael Scroggie, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Abraão Leite, Iain Reid, Martin
Kevil, Sean McCann, Mattia Menchetti, Becky Barnes, Elisabeth Östman,
Mali’o Kodis, image from the “Proceedings of the Zoological Society of
London”, L. Shyamal, Pedro de Siracusa, Matt Martyniuk (modified by T.
Michael Keesey), Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Bill Bouton (source photo) & T. Michael
Keesey (vectorization), Yan Wong from photo by Gyik Toma, Josefine Bohr
Brask, Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Manabu Bessho-Uehara, Alexandre Vong, I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), , DW Bapst, modified from Figure 1 of
Belanger (2011, PALAIOS)., Dann Pigdon, Michele Tobias, Giant Blue
Anteater (vectorized by T. Michael Keesey), Jake Warner, Jimmy Bernot,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Cristian Osorio &
Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Thea Boodhoo (photograph) and T. Michael
Keesey (vectorization), Fir0002/Flagstaffotos (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Espen Horn
(model; vectorized by T. Michael Keesey from a photo by H. Zell),
Acrocynus (vectorized by T. Michael Keesey), Lee Harding (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Scott
Hartman (modified by T. Michael Keesey), Inessa Voet, xgirouxb, FunkMonk
(Michael B. H.), Prin Pattawaro (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Crystal Maier, Tyler McCraney, E. J.
Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael
Keesey), Cagri Cevrim, Ville-Veikko Sinkkonen, Mariana Ruiz (vectorized
by T. Michael Keesey), Robert Gay, modifed from Olegivvit, Andrew Farke
and Joseph Sertich, Anthony Caravaggi, . Original drawing by M. Antón,
published in Montoya and Morales 1984. Vectorized by O. Sanisidro,
Smokeybjb (vectorized by T. Michael Keesey), Mali’o Kodis, photograph by
Derek Keats (<http://www.flickr.com/photos/dkeats/>), Noah Schlottman,
photo by Reinhard Jahn, Christopher Chávez, Josep Marti Solans,
Stemonitis (photography) and T. Michael Keesey (vectorization), Allison
Pease, Ron Holmes/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), T. Michael Keesey (after Joseph Wolf),
Darius Nau, Jaime Headden, Ryan Cupo, Nobu Tamura (vectorized by A.
Verrière), Trond R. Oskars, Geoff Shaw, Oscar Sanisidro, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Darren Naish (vectorized by T. Michael Keesey), \[unknown\],
Peileppe, Jaime Headden (vectorized by T. Michael Keesey), Lip Kee Yap
(vectorized by T. Michael Keesey), Taro Maeda, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Stuart
Humphries

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    929.223688 |    618.523263 | Ferran Sayol                                                                                                                                                          |
|   2 |    835.122769 |    662.160143 | NA                                                                                                                                                                    |
|   3 |    772.662812 |    356.793170 | Lani Mohan                                                                                                                                                            |
|   4 |    388.718479 |    252.254435 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
|   5 |    147.666708 |    212.023131 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
|   6 |    214.819892 |    188.452293 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
|   7 |    348.421108 |    549.492568 | Chris huh                                                                                                                                                             |
|   8 |    588.452249 |    111.565387 | T. Michael Keesey                                                                                                                                                     |
|   9 |    428.327260 |    509.409065 | Scott Reid                                                                                                                                                            |
|  10 |    512.988367 |    469.657274 | Ferran Sayol                                                                                                                                                          |
|  11 |    945.964736 |    293.369504 | Jagged Fang Designs                                                                                                                                                   |
|  12 |    603.873991 |    299.763222 | zoosnow                                                                                                                                                               |
|  13 |    398.091557 |    393.806624 | Kamil S. Jaron                                                                                                                                                        |
|  14 |    720.789913 |    644.697023 | Michelle Site                                                                                                                                                         |
|  15 |     53.420235 |    433.828241 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  16 |    614.823826 |    566.007424 | NA                                                                                                                                                                    |
|  17 |    567.062589 |    657.504515 | Steven Traver                                                                                                                                                         |
|  18 |    911.854991 |    715.572833 | Alex Slavenko                                                                                                                                                         |
|  19 |    244.940206 |    357.599407 | Zimices                                                                                                                                                               |
|  20 |    704.754383 |    529.615021 | Scott Hartman                                                                                                                                                         |
|  21 |    899.234375 |    103.942487 | Matt Crook                                                                                                                                                            |
|  22 |    447.560464 |    755.175991 | Dean Schnabel                                                                                                                                                         |
|  23 |    775.234758 |     78.019416 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
|  24 |    931.332710 |    374.321418 | Steven Traver                                                                                                                                                         |
|  25 |    309.544639 |    472.472789 | Margot Michaud                                                                                                                                                        |
|  26 |    637.489037 |    437.635269 | Martin R. Smith                                                                                                                                                       |
|  27 |    824.947904 |     45.742820 | Scott Hartman                                                                                                                                                         |
|  28 |    301.821903 |    645.578110 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
|  29 |    772.220581 |    224.817375 | Catherine Yasuda                                                                                                                                                      |
|  30 |    286.772494 |    692.559249 | Margot Michaud                                                                                                                                                        |
|  31 |    214.909201 |    298.912374 | Margot Michaud                                                                                                                                                        |
|  32 |     94.787333 |    662.228819 | Benjamint444                                                                                                                                                          |
|  33 |    840.637490 |    560.311235 | Jagged Fang Designs                                                                                                                                                   |
|  34 |    475.905466 |    584.068010 | Jagged Fang Designs                                                                                                                                                   |
|  35 |    153.343553 |    461.015384 | Matt Crook                                                                                                                                                            |
|  36 |    508.556751 |    179.051579 | NA                                                                                                                                                                    |
|  37 |    399.993906 |    621.236621 | C. Camilo Julián-Caballero                                                                                                                                            |
|  38 |    829.881841 |    381.723622 | Gareth Monger                                                                                                                                                         |
|  39 |    720.010054 |    736.497415 | Carlos Cano-Barbacil                                                                                                                                                  |
|  40 |    277.667128 |     80.102255 | Matt Crook                                                                                                                                                            |
|  41 |    477.824808 |     74.833259 | Gareth Monger                                                                                                                                                         |
|  42 |    667.581444 |    596.816956 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
|  43 |    110.432719 |     57.070133 | Rebecca Groom                                                                                                                                                         |
|  44 |    185.731820 |    720.143682 | Chloé Schmidt                                                                                                                                                         |
|  45 |    810.512808 |    447.651826 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
|  46 |    246.640894 |    538.033644 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  47 |    708.887280 |    118.295671 | Matt Martyniuk                                                                                                                                                        |
|  48 |    925.693386 |    213.124892 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  49 |    513.398241 |    256.962638 | Margot Michaud                                                                                                                                                        |
|  50 |     77.964849 |    756.817963 | Birgit Lang                                                                                                                                                           |
|  51 |    117.969574 |    135.437942 | NA                                                                                                                                                                    |
|  52 |    307.778853 |    257.629097 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
|  53 |    183.679462 |    577.062027 | NA                                                                                                                                                                    |
|  54 |     39.126062 |    171.981188 | Peter Coxhead                                                                                                                                                         |
|  55 |    618.850142 |    204.957660 | Lani Mohan                                                                                                                                                            |
|  56 |    374.697359 |     51.137440 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
|  57 |    946.435710 |    756.716248 | Steven Traver                                                                                                                                                         |
|  58 |    325.347258 |    602.063317 | Mathew Wedel                                                                                                                                                          |
|  59 |    935.032632 |    256.018166 | Chris huh                                                                                                                                                             |
|  60 |    953.167050 |    537.941762 | T. Michael Keesey                                                                                                                                                     |
|  61 |    355.298223 |    156.844418 | Scott Reid                                                                                                                                                            |
|  62 |    199.076962 |    767.325366 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  63 |    948.080044 |    456.904507 | Rebecca Groom                                                                                                                                                         |
|  64 |    153.324197 |    533.063935 | Matt Crook                                                                                                                                                            |
|  65 |    410.634267 |    685.404686 | Harold N Eyster                                                                                                                                                       |
|  66 |    567.156137 |     46.685927 | Manabu Sakamoto                                                                                                                                                       |
|  67 |    484.991669 |    330.637901 | Yan Wong                                                                                                                                                              |
|  68 |    859.537904 |    733.072942 | Jagged Fang Designs                                                                                                                                                   |
|  69 |    682.990251 |    412.967224 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
|  70 |    160.586381 |     24.638369 | Scott Hartman                                                                                                                                                         |
|  71 |    310.788995 |    756.121958 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  72 |    634.754603 |    776.947616 | Matt Dempsey                                                                                                                                                          |
|  73 |    576.593355 |    424.256291 | T. Michael Keesey                                                                                                                                                     |
|  74 |    705.551136 |    495.417591 | Dmitry Bogdanov                                                                                                                                                       |
|  75 |     32.634142 |    656.595188 | Ferran Sayol                                                                                                                                                          |
|  76 |    224.819046 |    614.464052 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
|  77 |    929.160018 |    485.094123 | Scott Hartman                                                                                                                                                         |
|  78 |    959.507212 |    164.994215 | Chris huh                                                                                                                                                             |
|  79 |    551.759994 |    569.757371 | Ferran Sayol                                                                                                                                                          |
|  80 |    735.932099 |    435.397431 | Roberto Díaz Sibaja                                                                                                                                                   |
|  81 |    748.183733 |    292.339940 | Scott Reid                                                                                                                                                            |
|  82 |    509.130442 |    650.117077 | Matt Martyniuk                                                                                                                                                        |
|  83 |    249.307057 |    503.704370 | Gareth Monger                                                                                                                                                         |
|  84 |    423.937761 |     29.150424 | Margot Michaud                                                                                                                                                        |
|  85 |    632.315127 |    357.966308 | Tauana J. Cunha                                                                                                                                                       |
|  86 |    763.801711 |    664.928156 | Maija Karala                                                                                                                                                          |
|  87 |    952.105883 |    654.842471 | Margot Michaud                                                                                                                                                        |
|  88 |    704.701749 |    301.823975 | Mathilde Cordellier                                                                                                                                                   |
|  89 |    799.213613 |    735.125743 | Gareth Monger                                                                                                                                                         |
|  90 |    453.286522 |    142.576507 | Tauana J. Cunha                                                                                                                                                       |
|  91 |    542.891848 |    739.524263 | Zimices                                                                                                                                                               |
|  92 |    535.135958 |    684.998884 | Emily Willoughby                                                                                                                                                      |
|  93 |    564.754301 |    225.743115 | Scott Hartman                                                                                                                                                         |
|  94 |    294.886297 |     24.182416 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  95 |    461.953012 |    264.028291 | Emma Kissling                                                                                                                                                         |
|  96 |    124.153976 |    414.180952 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
|  97 |    980.873211 |    613.074711 | NA                                                                                                                                                                    |
|  98 |    586.848451 |    209.886892 | Matt Crook                                                                                                                                                            |
|  99 |    371.605059 |    444.634102 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    260.703550 |    417.599993 | Margot Michaud                                                                                                                                                        |
| 101 |    590.799064 |    477.215391 | Margot Michaud                                                                                                                                                        |
| 102 |    184.361364 |    224.933922 | Gopal Murali                                                                                                                                                          |
| 103 |    725.607601 |    337.824274 | Margot Michaud                                                                                                                                                        |
| 104 |     16.582756 |    577.039473 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 105 |    378.357728 |     16.756706 | Jagged Fang Designs                                                                                                                                                   |
| 106 |     25.474366 |    771.024877 | Manabu Sakamoto                                                                                                                                                       |
| 107 |    694.547792 |    487.981876 | Zimices                                                                                                                                                               |
| 108 |    238.112064 |    661.167114 | NA                                                                                                                                                                    |
| 109 |    717.046320 |    568.107344 | Matt Crook                                                                                                                                                            |
| 110 |     34.289265 |    723.771505 | Dean Schnabel                                                                                                                                                         |
| 111 |    986.757510 |    328.815079 | David Orr                                                                                                                                                             |
| 112 |    768.946669 |     48.499882 | Jagged Fang Designs                                                                                                                                                   |
| 113 |    577.829414 |    571.897004 | Rene Martin                                                                                                                                                           |
| 114 |    547.359392 |    308.736687 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 115 |    785.942683 |    144.747763 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 116 |    575.475240 |    545.217836 | Matt Crook                                                                                                                                                            |
| 117 |    665.260660 |    686.155998 | NA                                                                                                                                                                    |
| 118 |    619.597832 |    697.334606 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 119 |    643.355172 |     46.990756 | Lukasiniho                                                                                                                                                            |
| 120 |    518.433589 |    572.666093 | TaraTaylorDesign                                                                                                                                                      |
| 121 |    666.644396 |     71.754742 | Birgit Lang                                                                                                                                                           |
| 122 |    770.230754 |    206.095471 | Gareth Monger                                                                                                                                                         |
| 123 |    820.177208 |    485.240894 | Renata F. Martins                                                                                                                                                     |
| 124 |    330.761344 |    102.983713 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 125 |    111.761651 |      6.901370 | Katie S. Collins                                                                                                                                                      |
| 126 |    153.689016 |    256.144875 | Gareth Monger                                                                                                                                                         |
| 127 |    956.817796 |    129.479296 | Sharon Wegner-Larsen                                                                                                                                                  |
| 128 |     62.411432 |    106.963651 | Robert Gay                                                                                                                                                            |
| 129 |    129.994763 |    284.373283 | C. Camilo Julián-Caballero                                                                                                                                            |
| 130 |    998.366756 |    529.737120 | Chris huh                                                                                                                                                             |
| 131 |    136.226033 |    107.460440 | Matt Crook                                                                                                                                                            |
| 132 |    406.982344 |    348.357664 | David Orr                                                                                                                                                             |
| 133 |     43.485202 |     64.175463 | Andrew A. Farke                                                                                                                                                       |
| 134 |    599.677278 |    166.540506 | Gareth Monger                                                                                                                                                         |
| 135 |    414.033127 |    336.351424 | Margot Michaud                                                                                                                                                        |
| 136 |    458.208908 |    663.921529 | Scott Hartman                                                                                                                                                         |
| 137 |    109.445100 |    226.441762 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                     |
| 138 |   1006.454312 |     79.638059 | Ferran Sayol                                                                                                                                                          |
| 139 |    121.598898 |    324.185325 | Steven Traver                                                                                                                                                         |
| 140 |    991.308341 |    103.822184 | CNZdenek                                                                                                                                                              |
| 141 |    950.184075 |    142.103032 | Zimices                                                                                                                                                               |
| 142 |    824.846852 |     22.510696 | Qiang Ou                                                                                                                                                              |
| 143 |    744.799592 |    184.920592 | Steven Traver                                                                                                                                                         |
| 144 |    998.303313 |    475.743801 | Chris huh                                                                                                                                                             |
| 145 |    490.544565 |    124.461433 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 146 |    363.288964 |    126.885712 | Scott Hartman                                                                                                                                                         |
| 147 |     99.887308 |    385.193122 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 148 |    483.548313 |    549.912227 | Ferran Sayol                                                                                                                                                          |
| 149 |    236.151399 |    463.317594 | Blair Perry                                                                                                                                                           |
| 150 |     64.795171 |     87.932069 | Shyamal                                                                                                                                                               |
| 151 |    368.887746 |     47.504336 | Margot Michaud                                                                                                                                                        |
| 152 |    209.492966 |    385.926585 | Chris huh                                                                                                                                                             |
| 153 |    638.888222 |    723.211967 | Gareth Monger                                                                                                                                                         |
| 154 |    229.670364 |    253.920773 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 155 |    136.008458 |    308.144260 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 156 |     38.972730 |    537.653449 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 157 |    229.178163 |    510.726853 | Christine Axon                                                                                                                                                        |
| 158 |    443.094562 |    458.477332 | Chris huh                                                                                                                                                             |
| 159 |    351.684752 |    309.049986 | Gareth Monger                                                                                                                                                         |
| 160 |    351.108318 |    578.343561 | Gareth Monger                                                                                                                                                         |
| 161 |    974.363838 |    586.335886 | Matt Crook                                                                                                                                                            |
| 162 |    818.125917 |    761.895910 | Nina Skinner                                                                                                                                                          |
| 163 |    532.279000 |    524.320263 | Rebecca Groom                                                                                                                                                         |
| 164 |    450.927199 |    295.339442 | T. Michael Keesey                                                                                                                                                     |
| 165 |    403.780365 |    594.864196 | Margot Michaud                                                                                                                                                        |
| 166 |   1001.521318 |    407.826009 | Gareth Monger                                                                                                                                                         |
| 167 |    791.260780 |    538.941003 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 168 |    876.681221 |    443.117667 | Steven Traver                                                                                                                                                         |
| 169 |    836.311523 |    695.938533 | Ferran Sayol                                                                                                                                                          |
| 170 |    620.323189 |    484.429272 | Ludwik Gasiorowski                                                                                                                                                    |
| 171 |    768.081443 |    757.485224 | NA                                                                                                                                                                    |
| 172 |    773.475622 |    702.720650 | Zimices                                                                                                                                                               |
| 173 |    359.730693 |    570.136320 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 174 |    800.768261 |    695.296936 | Dean Schnabel                                                                                                                                                         |
| 175 |     65.905334 |    202.562436 | Birgit Lang                                                                                                                                                           |
| 176 |    282.620178 |     75.594394 | Benjamint444                                                                                                                                                          |
| 177 |    948.057136 |    339.418147 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                          |
| 178 |     57.622889 |     56.994741 | T. Michael Keesey                                                                                                                                                     |
| 179 |    485.686415 |    615.636721 | Luis Cunha                                                                                                                                                            |
| 180 |    869.375713 |    262.447702 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
| 181 |    291.640386 |    721.869720 | NA                                                                                                                                                                    |
| 182 |    419.875717 |    558.790934 | Collin Gross                                                                                                                                                          |
| 183 |   1002.857324 |    578.468778 | Julio Garza                                                                                                                                                           |
| 184 |    356.269178 |    288.816444 | NA                                                                                                                                                                    |
| 185 |    145.192834 |    627.505821 | Jonathan Wells                                                                                                                                                        |
| 186 |    170.204100 |     36.432686 | Ferran Sayol                                                                                                                                                          |
| 187 |    346.238036 |    428.146626 | Jakovche                                                                                                                                                              |
| 188 |    754.788386 |    697.084374 | Oliver Griffith                                                                                                                                                       |
| 189 |    791.430361 |    794.865806 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 190 |    226.296365 |    741.789955 | Beth Reinke                                                                                                                                                           |
| 191 |    190.213364 |    101.504235 | Tasman Dixon                                                                                                                                                          |
| 192 |    436.374489 |    122.813675 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 193 |    706.633678 |    366.405652 | NA                                                                                                                                                                    |
| 194 |     44.672413 |    774.275584 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 195 |    367.913446 |    328.274853 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 196 |    338.705483 |    108.043073 | Dean Schnabel                                                                                                                                                         |
| 197 |    572.360116 |    455.886599 | Gareth Monger                                                                                                                                                         |
| 198 |     50.318804 |    422.480963 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 199 |    778.757469 |      4.639110 | Scott Hartman                                                                                                                                                         |
| 200 |    166.691173 |    164.895021 | Margot Michaud                                                                                                                                                        |
| 201 |    876.520812 |     53.499076 | Scott Hartman                                                                                                                                                         |
| 202 |    745.305390 |     13.105019 | Matt Crook                                                                                                                                                            |
| 203 |    704.070432 |    767.039187 | Collin Gross                                                                                                                                                          |
| 204 |    979.842955 |    519.977495 | Joanna Wolfe                                                                                                                                                          |
| 205 |    664.189207 |    347.046242 | NA                                                                                                                                                                    |
| 206 |    349.580559 |     99.560411 | (after Spotila 2004)                                                                                                                                                  |
| 207 |    254.063780 |    227.333482 | Chloé Schmidt                                                                                                                                                         |
| 208 |    255.858837 |     23.119526 | Matt Crook                                                                                                                                                            |
| 209 |    652.680120 |    784.676612 | Birgit Lang                                                                                                                                                           |
| 210 |    631.939558 |    614.755483 | David Orr                                                                                                                                                             |
| 211 |    108.976631 |    205.561515 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 212 |    795.070032 |    585.148670 | Michael P. Taylor                                                                                                                                                     |
| 213 |    666.909687 |    473.507316 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 214 |    270.779103 |     19.664528 | Michelle Site                                                                                                                                                         |
| 215 |    667.767276 |    258.553794 | Birgit Lang                                                                                                                                                           |
| 216 |    757.292684 |    677.323349 | Xavier Giroux-Bougard                                                                                                                                                 |
| 217 |    123.655645 |     96.287625 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 218 |    525.303985 |    746.482323 | Kimberly Haddrell                                                                                                                                                     |
| 219 |     51.570442 |    130.585793 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 220 |    855.354463 |    360.914399 | NA                                                                                                                                                                    |
| 221 |    717.402517 |    353.846203 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 222 |    554.860226 |     15.100411 | Matt Crook                                                                                                                                                            |
| 223 |    857.432498 |    619.945918 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 224 |    745.415785 |    465.046799 | Steven Traver                                                                                                                                                         |
| 225 |    644.987284 |    659.229384 | Dmitry Bogdanov                                                                                                                                                       |
| 226 |     80.694475 |    789.119210 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 227 |    307.380083 |    664.080333 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 228 |    451.882491 |    466.412825 | Matthew E. Clapham                                                                                                                                                    |
| 229 |    430.196109 |     70.082601 | Scott Hartman                                                                                                                                                         |
| 230 |   1001.169599 |    266.245513 | Ferran Sayol                                                                                                                                                          |
| 231 |    736.882890 |    577.137853 | kreidefossilien.de                                                                                                                                                    |
| 232 |    166.009283 |    500.987097 | Maija Karala                                                                                                                                                          |
| 233 |    514.419498 |    403.824310 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 234 |    852.949144 |     12.722919 | NA                                                                                                                                                                    |
| 235 |    106.026920 |    259.012246 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 236 |     18.588396 |    546.154324 | Matus Valach                                                                                                                                                          |
| 237 |    686.929684 |    786.873190 | Margot Michaud                                                                                                                                                        |
| 238 |    133.190849 |    604.162545 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 239 |    986.295774 |    228.510931 | Gareth Monger                                                                                                                                                         |
| 240 |    210.980773 |     82.148989 | NA                                                                                                                                                                    |
| 241 |    284.238730 |    171.931509 | Steven Traver                                                                                                                                                         |
| 242 |     20.938253 |    259.729875 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 243 |    332.624309 |    286.432927 | Gareth Monger                                                                                                                                                         |
| 244 |    269.831063 |    609.384067 | Sarah Alewijnse                                                                                                                                                       |
| 245 |    339.798251 |    326.732444 | Zimices                                                                                                                                                               |
| 246 |    693.630860 |    687.630595 | Kamil S. Jaron                                                                                                                                                        |
| 247 |    871.687990 |    586.732364 | Maxime Dahirel                                                                                                                                                        |
| 248 |    183.267018 |    652.719688 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 249 |    178.540394 |    211.003274 | Zimices                                                                                                                                                               |
| 250 |     97.328422 |    440.503995 | Dean Schnabel                                                                                                                                                         |
| 251 |    856.340193 |    789.447075 | Chris huh                                                                                                                                                             |
| 252 |   1021.025372 |    345.237722 | NA                                                                                                                                                                    |
| 253 |    800.338344 |    218.324451 | François Michonneau                                                                                                                                                   |
| 254 |    139.780430 |    397.999828 | Melissa Broussard                                                                                                                                                     |
| 255 |    782.766163 |    601.334920 | SauropodomorphMonarch                                                                                                                                                 |
| 256 |    349.646113 |    373.417394 | Caleb M. Brown                                                                                                                                                        |
| 257 |    841.499496 |    217.839084 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 258 |    537.225189 |    725.015227 | Gareth Monger                                                                                                                                                         |
| 259 |    873.899106 |    328.642896 | Neil Kelley                                                                                                                                                           |
| 260 |    989.182536 |    672.528261 | Renata F. Martins                                                                                                                                                     |
| 261 |     14.565933 |    750.544476 | Kent Elson Sorgon                                                                                                                                                     |
| 262 |   1006.970465 |    322.464476 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 263 |    968.557585 |    285.945626 | Gareth Monger                                                                                                                                                         |
| 264 |    883.502016 |    352.165228 | Scott Hartman                                                                                                                                                         |
| 265 |    548.801922 |    681.076696 | Matt Crook                                                                                                                                                            |
| 266 |    230.166770 |    697.292503 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 267 |    731.378547 |    165.807332 | FunkMonk                                                                                                                                                              |
| 268 |    570.658576 |    390.118165 | NA                                                                                                                                                                    |
| 269 |     27.609979 |    557.842332 | Steven Traver                                                                                                                                                         |
| 270 |    742.047395 |    672.129803 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 271 |     86.631455 |    638.779829 | Margot Michaud                                                                                                                                                        |
| 272 |    783.479457 |    193.950391 | Maija Karala                                                                                                                                                          |
| 273 |    239.875719 |    554.254088 | T. Michael Keesey                                                                                                                                                     |
| 274 |   1014.069182 |    382.530955 | Tracy A. Heath                                                                                                                                                        |
| 275 |    693.494317 |    196.402456 | Margot Michaud                                                                                                                                                        |
| 276 |    481.670941 |    679.525975 | Steven Traver                                                                                                                                                         |
| 277 |    996.768820 |    540.349365 | Gareth Monger                                                                                                                                                         |
| 278 |    670.867945 |    108.506720 | Jagged Fang Designs                                                                                                                                                   |
| 279 |     64.686406 |    723.099181 | Margot Michaud                                                                                                                                                        |
| 280 |    524.993418 |    715.113213 | Margot Michaud                                                                                                                                                        |
| 281 |    206.079406 |     40.996739 | Steven Traver                                                                                                                                                         |
| 282 |    278.086240 |     47.527647 | Matt Martyniuk                                                                                                                                                        |
| 283 |    463.053336 |    102.296222 | Chloé Schmidt                                                                                                                                                         |
| 284 |    562.668174 |    782.646962 | T. Michael Keesey                                                                                                                                                     |
| 285 |    217.387265 |    224.827923 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 286 |    226.471707 |    431.749395 | Cristopher Silva                                                                                                                                                      |
| 287 |    161.923662 |    381.977089 | Scott Hartman                                                                                                                                                         |
| 288 |    188.302671 |    122.999963 | NA                                                                                                                                                                    |
| 289 |    957.179995 |    495.874519 | Joanna Wolfe                                                                                                                                                          |
| 290 |    987.429869 |    348.581374 | Steven Traver                                                                                                                                                         |
| 291 |    668.025268 |    201.534284 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 292 |   1004.886066 |    640.857136 | SauropodomorphMonarch                                                                                                                                                 |
| 293 |    225.441130 |    485.724941 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 294 |     99.144421 |    216.955161 | Jagged Fang Designs                                                                                                                                                   |
| 295 |    140.471856 |    678.342950 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 296 |     15.556006 |    363.789414 | Kent Elson Sorgon                                                                                                                                                     |
| 297 |    430.128729 |    303.840001 | Renata F. Martins                                                                                                                                                     |
| 298 |     84.671066 |    169.477726 | Jagged Fang Designs                                                                                                                                                   |
| 299 |    774.314410 |    627.635672 | Hans Hillewaert                                                                                                                                                       |
| 300 |    298.044998 |    156.614504 | Sarah Werning                                                                                                                                                         |
| 301 |    404.632888 |    168.751198 | Emily Willoughby                                                                                                                                                      |
| 302 |    261.530302 |    242.881115 | Matt Crook                                                                                                                                                            |
| 303 |    654.548875 |    625.155071 | Ferran Sayol                                                                                                                                                          |
| 304 |    512.926455 |    492.611242 | Tasman Dixon                                                                                                                                                          |
| 305 |   1004.612784 |    686.631949 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 306 |    693.125805 |    203.593983 | Scott Hartman                                                                                                                                                         |
| 307 |    256.799079 |    581.664667 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 308 |    735.292846 |    356.428747 | Yan Wong                                                                                                                                                              |
| 309 |    308.114624 |    317.355280 | Birgit Lang                                                                                                                                                           |
| 310 |    434.228433 |    314.473740 | Zimices                                                                                                                                                               |
| 311 |     88.563554 |    477.759983 | Matt Crook                                                                                                                                                            |
| 312 |    284.292990 |    294.056250 | Zimices                                                                                                                                                               |
| 313 |    101.654126 |    464.893735 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 314 |     90.496759 |    211.912077 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 315 |     90.948543 |    543.732033 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 316 |    246.820501 |    148.716875 | NA                                                                                                                                                                    |
| 317 |    764.196572 |     20.057734 | Gareth Monger                                                                                                                                                         |
| 318 |    391.243448 |      5.603022 | Mykle Hoban                                                                                                                                                           |
| 319 |    312.363576 |    408.451828 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 320 |    192.517713 |    772.163003 | Margot Michaud                                                                                                                                                        |
| 321 |    392.750133 |    492.809223 | Jagged Fang Designs                                                                                                                                                   |
| 322 |    422.558835 |     11.264611 | Matt Crook                                                                                                                                                            |
| 323 |    754.076033 |    389.241785 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 324 |     30.675780 |    488.639567 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 325 |    761.204772 |    447.473951 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 326 |    375.784124 |    577.255746 | Hans Hillewaert                                                                                                                                                       |
| 327 |    435.444321 |    164.453342 | Margot Michaud                                                                                                                                                        |
| 328 |    413.948808 |    187.885441 | Steven Traver                                                                                                                                                         |
| 329 |    449.611707 |    379.552358 | Jagged Fang Designs                                                                                                                                                   |
| 330 |    694.046663 |    668.623140 | Ferran Sayol                                                                                                                                                          |
| 331 |    585.405244 |    696.683489 | Rebecca Groom                                                                                                                                                         |
| 332 |    599.642084 |    719.851630 | Margot Michaud                                                                                                                                                        |
| 333 |    383.951629 |    456.479712 | Michelle Site                                                                                                                                                         |
| 334 |    617.662703 |     19.741560 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 335 |     10.551626 |    175.373889 | Steven Traver                                                                                                                                                         |
| 336 |    170.709841 |    663.244475 | Gareth Monger                                                                                                                                                         |
| 337 |    231.160098 |     40.212851 | Gareth Monger                                                                                                                                                         |
| 338 |    708.993926 |    269.784925 | Christoph Schomburg                                                                                                                                                   |
| 339 |    753.179507 |    557.152380 | Matt Crook                                                                                                                                                            |
| 340 |    600.765699 |    371.046826 | T. Michael Keesey                                                                                                                                                     |
| 341 |    517.338461 |    437.905261 | Margot Michaud                                                                                                                                                        |
| 342 |    577.964140 |    501.101534 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 343 |    414.233940 |    590.621529 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 344 |    839.042900 |    625.474443 | Tauana J. Cunha                                                                                                                                                       |
| 345 |    987.803959 |    295.371412 | NA                                                                                                                                                                    |
| 346 |    564.662926 |    242.955436 | Margot Michaud                                                                                                                                                        |
| 347 |    378.704118 |    509.897329 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 348 |    908.136957 |    413.439474 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 349 |    778.293443 |    481.757227 | Tauana J. Cunha                                                                                                                                                       |
| 350 |     85.139165 |    750.721228 | Birgit Lang                                                                                                                                                           |
| 351 |   1011.267702 |    498.282142 | Gareth Monger                                                                                                                                                         |
| 352 |    433.144807 |    533.604553 | Katie S. Collins                                                                                                                                                      |
| 353 |    638.254039 |    523.723414 | Sharon Wegner-Larsen                                                                                                                                                  |
| 354 |    203.243939 |    116.658740 | Roberto Díaz Sibaja                                                                                                                                                   |
| 355 |    553.974593 |    716.594113 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 356 |     41.247912 |    583.218162 | Beth Reinke                                                                                                                                                           |
| 357 |    779.856943 |    220.065303 | Ferran Sayol                                                                                                                                                          |
| 358 |    867.062167 |    618.061315 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 359 |    184.598954 |    684.203016 | Michelle Site                                                                                                                                                         |
| 360 |    241.291367 |    278.015821 | Matt Crook                                                                                                                                                            |
| 361 |    749.157843 |    274.294943 | Dean Schnabel                                                                                                                                                         |
| 362 |    841.642368 |    533.012488 | Gareth Monger                                                                                                                                                         |
| 363 |    326.194068 |    782.433390 | Ferran Sayol                                                                                                                                                          |
| 364 |    459.552509 |      9.436478 | Chris huh                                                                                                                                                             |
| 365 |    214.226450 |    792.323851 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 366 |     85.307090 |    466.036202 | Emily Willoughby                                                                                                                                                      |
| 367 |    308.678464 |    533.625213 | Margot Michaud                                                                                                                                                        |
| 368 |    443.822774 |    272.637143 | Steven Coombs                                                                                                                                                         |
| 369 |    175.472194 |    633.137779 | Yan Wong                                                                                                                                                              |
| 370 |    200.251196 |    553.857444 | Chris huh                                                                                                                                                             |
| 371 |    381.042840 |    114.625305 | Margot Michaud                                                                                                                                                        |
| 372 |   1001.960537 |    120.120303 | NA                                                                                                                                                                    |
| 373 |    884.959521 |    313.896430 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 374 |    703.557557 |     32.465306 | Tasman Dixon                                                                                                                                                          |
| 375 |    693.324671 |     88.841627 | Steven Traver                                                                                                                                                         |
| 376 |    262.439438 |    448.501654 | B. Duygu Özpolat                                                                                                                                                      |
| 377 |    111.250032 |    359.589729 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 378 |    333.562223 |    628.100400 | Steven Traver                                                                                                                                                         |
| 379 |    753.159872 |    409.792352 | T. Michael Keesey                                                                                                                                                     |
| 380 |     35.935540 |    793.955520 | Smokeybjb                                                                                                                                                             |
| 381 |    794.210089 |    251.713486 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 382 |    415.186097 |     84.971634 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 383 |    778.358150 |    666.552950 | Alex Slavenko                                                                                                                                                         |
| 384 |    166.492893 |    113.420294 | Gareth Monger                                                                                                                                                         |
| 385 |    167.726160 |    636.166383 | Gareth Monger                                                                                                                                                         |
| 386 |    416.851870 |     92.839504 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 387 |    527.587218 |    760.223386 | Margot Michaud                                                                                                                                                        |
| 388 |     87.805243 |    578.794603 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 389 |    795.324719 |    578.165072 | Zimices                                                                                                                                                               |
| 390 |    575.613000 |    519.863130 | Beth Reinke                                                                                                                                                           |
| 391 |    553.116408 |    251.737727 | Zimices                                                                                                                                                               |
| 392 |    290.880153 |    318.561343 | Birgit Lang                                                                                                                                                           |
| 393 |    361.846107 |    391.834837 | Chris huh                                                                                                                                                             |
| 394 |    328.709978 |    334.351844 | Oliver Voigt                                                                                                                                                          |
| 395 |    552.781725 |    587.634572 | Matt Crook                                                                                                                                                            |
| 396 |    798.679184 |    759.758057 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 397 |    886.546483 |    587.511468 | Jagged Fang Designs                                                                                                                                                   |
| 398 |    278.561377 |    616.374551 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 399 |    332.699883 |    296.577413 | Conty                                                                                                                                                                 |
| 400 |    494.914503 |    609.534631 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 401 |    948.869134 |    173.309948 | Pete Buchholz                                                                                                                                                         |
| 402 |    604.698502 |    640.666797 | Gareth Monger                                                                                                                                                         |
| 403 |    308.638957 |    132.363733 | Zimices                                                                                                                                                               |
| 404 |    511.232449 |    429.384284 | Harold N Eyster                                                                                                                                                       |
| 405 |    992.563998 |    594.383108 | Cesar Julian                                                                                                                                                          |
| 406 |    735.576038 |    455.801355 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 407 |    283.569411 |    730.235792 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 408 |    666.984062 |    335.771307 | Margot Michaud                                                                                                                                                        |
| 409 |    851.115515 |    444.066855 | Margot Michaud                                                                                                                                                        |
| 410 |    853.927021 |    232.609560 | Gareth Monger                                                                                                                                                         |
| 411 |    788.062395 |    170.982116 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 412 |    671.064463 |     32.862993 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 413 |    126.406594 |    260.200201 | Ferran Sayol                                                                                                                                                          |
| 414 |    875.103064 |     15.845100 | Joanna Wolfe                                                                                                                                                          |
| 415 |    164.072542 |    272.651760 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 416 |    696.248505 |    708.537663 | Chris huh                                                                                                                                                             |
| 417 |    811.368302 |    106.361614 | Margot Michaud                                                                                                                                                        |
| 418 |    647.503997 |    345.952712 | NA                                                                                                                                                                    |
| 419 |    881.256629 |    418.757842 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 420 |    114.035454 |    735.949262 | Scott Hartman                                                                                                                                                         |
| 421 |    297.977372 |     94.914036 | Zimices                                                                                                                                                               |
| 422 |    564.584615 |    742.572201 | Zimices                                                                                                                                                               |
| 423 |   1017.966320 |    263.507537 | Felix Vaux                                                                                                                                                            |
| 424 |    297.770854 |    178.536222 | Jagged Fang Designs                                                                                                                                                   |
| 425 |    264.690685 |    258.239451 | Ferran Sayol                                                                                                                                                          |
| 426 |    750.901408 |     37.014952 | Zimices                                                                                                                                                               |
| 427 |    793.643349 |    627.953343 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 428 |    985.407453 |      7.349722 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 429 |    223.356025 |    153.340291 | Christoph Schomburg                                                                                                                                                   |
| 430 |    596.478682 |    518.164124 | NA                                                                                                                                                                    |
| 431 |    171.693238 |    281.696943 | Jagged Fang Designs                                                                                                                                                   |
| 432 |    267.830962 |    313.839474 | Zimices                                                                                                                                                               |
| 433 |    341.192277 |    412.607727 | Felix Vaux                                                                                                                                                            |
| 434 |    645.592888 |    741.207747 | Gareth Monger                                                                                                                                                         |
| 435 |    805.333098 |     14.113484 | Tony Ayling                                                                                                                                                           |
| 436 |   1014.340603 |     13.857795 | Zimices                                                                                                                                                               |
| 437 |     84.856269 |    108.545206 | David Orr                                                                                                                                                             |
| 438 |    557.878477 |    165.727307 | Chris huh                                                                                                                                                             |
| 439 |    830.181516 |    793.120107 | Margot Michaud                                                                                                                                                        |
| 440 |    315.933707 |    227.582360 | Andrew A. Farke                                                                                                                                                       |
| 441 |    522.712546 |    663.527788 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 442 |    504.890433 |    673.282531 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 443 |    371.794235 |    500.942919 | Gareth Monger                                                                                                                                                         |
| 444 |    846.927393 |     24.898859 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 445 |    872.816451 |    287.250742 | Ferran Sayol                                                                                                                                                          |
| 446 |    404.748662 |    569.719158 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 447 |    824.037475 |    780.459295 | Ingo Braasch                                                                                                                                                          |
| 448 |    711.497176 |    282.572539 | Julia B McHugh                                                                                                                                                        |
| 449 |    142.499319 |    346.795217 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 450 |    352.150013 |    403.731214 | Scott Hartman                                                                                                                                                         |
| 451 |    218.236190 |    776.495629 | Margot Michaud                                                                                                                                                        |
| 452 |    730.935393 |    795.630046 | Carlos Cano-Barbacil                                                                                                                                                  |
| 453 |    130.585376 |    377.176219 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 454 |     26.410113 |     99.160646 | Scott Hartman                                                                                                                                                         |
| 455 |    824.491952 |    758.025111 | Birgit Lang                                                                                                                                                           |
| 456 |    851.213488 |    317.426111 | Matt Crook                                                                                                                                                            |
| 457 |    296.414567 |    581.757034 | Scott Hartman                                                                                                                                                         |
| 458 |    425.734747 |    400.047055 | NA                                                                                                                                                                    |
| 459 |    455.117544 |    256.518900 | Joanna Wolfe                                                                                                                                                          |
| 460 |    851.275843 |     75.210876 | NA                                                                                                                                                                    |
| 461 |    448.082121 |    161.065443 | Cristopher Silva                                                                                                                                                      |
| 462 |    197.034440 |    262.519942 | Gopal Murali                                                                                                                                                          |
| 463 |    752.362385 |    340.590057 | Zimices                                                                                                                                                               |
| 464 |    542.222851 |    552.897939 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 465 |    483.794546 |    493.370978 | Zimices                                                                                                                                                               |
| 466 |    602.281517 |    245.093135 | Gareth Monger                                                                                                                                                         |
| 467 |    893.158493 |    539.464526 | Maija Karala                                                                                                                                                          |
| 468 |    807.785123 |    483.294185 | Zimices                                                                                                                                                               |
| 469 |     29.241437 |    466.512109 | Tracy A. Heath                                                                                                                                                        |
| 470 |    266.129547 |    597.283908 | NA                                                                                                                                                                    |
| 471 |    182.026521 |    237.941203 | Ferran Sayol                                                                                                                                                          |
| 472 |    356.212776 |    204.369443 | Joanna Wolfe                                                                                                                                                          |
| 473 |    217.941567 |    244.110020 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 474 |    461.719721 |    702.342129 | Matt Crook                                                                                                                                                            |
| 475 |   1008.546061 |    429.267334 | Terpsichores                                                                                                                                                          |
| 476 |    434.771276 |    288.959941 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 477 |    762.991591 |    684.230578 | Matt Crook                                                                                                                                                            |
| 478 |    461.533199 |    447.600799 | Margot Michaud                                                                                                                                                        |
| 479 |    182.376923 |    143.097191 | Gareth Monger                                                                                                                                                         |
| 480 |     20.855186 |    711.269521 | Lukasiniho                                                                                                                                                            |
| 481 |    630.991695 |    341.695740 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 482 |    421.162291 |    259.819525 | Steven Traver                                                                                                                                                         |
| 483 |    343.691550 |    385.780949 | Katie S. Collins                                                                                                                                                      |
| 484 |    730.750504 |    112.331004 | Felix Vaux                                                                                                                                                            |
| 485 |    585.945813 |    174.072394 | Matt Crook                                                                                                                                                            |
| 486 |    195.073821 |    634.374414 | Birgit Lang                                                                                                                                                           |
| 487 |    332.087012 |    654.803379 | Matt Crook                                                                                                                                                            |
| 488 |    500.073205 |    511.418958 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 489 |    607.215233 |    463.961962 | Chris huh                                                                                                                                                             |
| 490 |    163.636685 |    486.186047 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 491 |    165.943744 |      9.892366 | Margot Michaud                                                                                                                                                        |
| 492 |    381.313422 |     37.868212 | Shyamal                                                                                                                                                               |
| 493 |    448.896485 |     89.537936 | Cesar Julian                                                                                                                                                          |
| 494 |    852.877118 |    422.253606 | NA                                                                                                                                                                    |
| 495 |    316.138006 |    388.401771 | Mathieu Basille                                                                                                                                                       |
| 496 |    598.003227 |    185.981720 | New York Zoological Society                                                                                                                                           |
| 497 |    977.731210 |    693.868233 | Zimices                                                                                                                                                               |
| 498 |    655.747105 |    632.055887 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 499 |    880.900468 |     39.138474 | kotik                                                                                                                                                                 |
| 500 |    552.644549 |    542.342454 | Ferran Sayol                                                                                                                                                          |
| 501 |    290.948766 |    502.351409 | Matt Crook                                                                                                                                                            |
| 502 |    156.863118 |    419.040088 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 503 |    474.402986 |    285.030649 | Rebecca Groom                                                                                                                                                         |
| 504 |     72.252696 |    192.247977 | Beth Reinke                                                                                                                                                           |
| 505 |    776.472486 |    516.353019 | Margot Michaud                                                                                                                                                        |
| 506 |    401.159898 |     12.859576 | Gareth Monger                                                                                                                                                         |
| 507 |    848.839412 |    409.092061 | T. Michael Keesey                                                                                                                                                     |
| 508 |    989.442598 |    380.735440 | Mathilde Cordellier                                                                                                                                                   |
| 509 |    223.470667 |    629.985954 | Xavier Giroux-Bougard                                                                                                                                                 |
| 510 |   1013.676748 |    109.658228 | NA                                                                                                                                                                    |
| 511 |    208.508094 |    737.014322 | Zachary Quigley                                                                                                                                                       |
| 512 |    797.581558 |    607.304432 | Frank Denota                                                                                                                                                          |
| 513 |    561.135416 |    267.497073 | NA                                                                                                                                                                    |
| 514 |    572.503469 |    431.561973 | Scott Hartman                                                                                                                                                         |
| 515 |    609.171965 |    678.485222 | NA                                                                                                                                                                    |
| 516 |    281.867650 |    573.473561 | Margot Michaud                                                                                                                                                        |
| 517 |    680.363268 |    341.239337 | Tasman Dixon                                                                                                                                                          |
| 518 |    954.564166 |    439.868060 | Scott Hartman                                                                                                                                                         |
| 519 |    313.272819 |    568.303563 | Margot Michaud                                                                                                                                                        |
| 520 |    363.551283 |    134.689721 | Michael P. Taylor                                                                                                                                                     |
| 521 |    454.837927 |    203.209513 | Ferran Sayol                                                                                                                                                          |
| 522 |    184.669671 |     75.764706 | Blair Perry                                                                                                                                                           |
| 523 |    879.883111 |    249.975601 | Michelle Site                                                                                                                                                         |
| 524 |    994.194397 |    510.575343 | Matt Crook                                                                                                                                                            |
| 525 |    863.664871 |    794.136400 | Zimices                                                                                                                                                               |
| 526 |     10.184718 |    129.447439 | Steven Traver                                                                                                                                                         |
| 527 |     13.939393 |    593.983831 | Christoph Schomburg                                                                                                                                                   |
| 528 |    907.985733 |    781.398635 | Zimices                                                                                                                                                               |
| 529 |   1002.634696 |    609.267277 | Matt Crook                                                                                                                                                            |
| 530 |    653.141243 |    710.173989 | Lauren Anderson                                                                                                                                                       |
| 531 |    209.925463 |     60.234384 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 532 |    543.936486 |    233.026904 | Margot Michaud                                                                                                                                                        |
| 533 |    681.583415 |    100.286538 | Kai R. Caspar                                                                                                                                                         |
| 534 |    606.066416 |    230.599103 | Katie S. Collins                                                                                                                                                      |
| 535 |    395.079420 |    465.508766 | Margot Michaud                                                                                                                                                        |
| 536 |    294.883697 |    510.927418 | Matt Crook                                                                                                                                                            |
| 537 |    710.560060 |    699.714203 | Steven Traver                                                                                                                                                         |
| 538 |     35.468144 |     48.163742 | Chris Jennings (Risiatto)                                                                                                                                             |
| 539 |    994.887853 |    645.293703 | NA                                                                                                                                                                    |
| 540 |    899.789326 |    729.473815 | Tasman Dixon                                                                                                                                                          |
| 541 |    996.545427 |    494.174533 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 542 |    833.272656 |    240.362476 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 543 |    867.523142 |    251.102909 | Jagged Fang Designs                                                                                                                                                   |
| 544 |    274.815558 |    242.777555 | Steven Traver                                                                                                                                                         |
| 545 |    348.449949 |    233.689033 | Christoph Schomburg                                                                                                                                                   |
| 546 |    209.958914 |    394.821290 | Felix Vaux                                                                                                                                                            |
| 547 |    630.747850 |    426.155901 | Matt Crook                                                                                                                                                            |
| 548 |    793.003749 |    776.721898 | Matt Crook                                                                                                                                                            |
| 549 |    101.639018 |    411.990749 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 550 |      1.593111 |    398.376466 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 551 |    310.703372 |    331.884018 | Gareth Monger                                                                                                                                                         |
| 552 |    410.211546 |    532.539205 | Ferran Sayol                                                                                                                                                          |
| 553 |    567.898541 |     25.267325 | Lukasiniho                                                                                                                                                            |
| 554 |    735.910916 |    783.360607 | Chris huh                                                                                                                                                             |
| 555 |    522.176114 |    781.738181 | Scott Hartman                                                                                                                                                         |
| 556 |    206.098085 |     73.756652 | NA                                                                                                                                                                    |
| 557 |    706.810450 |     64.514656 | Gopal Murali                                                                                                                                                          |
| 558 |    851.488313 |    509.105959 | Dean Schnabel                                                                                                                                                         |
| 559 |    300.812368 |    707.163282 | Margot Michaud                                                                                                                                                        |
| 560 |    781.171564 |    752.825630 | Margot Michaud                                                                                                                                                        |
| 561 |    748.927698 |    163.561069 | Tasman Dixon                                                                                                                                                          |
| 562 |    126.320029 |    746.581532 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 563 |    573.033795 |    605.662619 | Margot Michaud                                                                                                                                                        |
| 564 |    396.450849 |    524.858733 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 565 |    790.624982 |    682.692080 | Ferran Sayol                                                                                                                                                          |
| 566 |    452.291312 |    217.284711 | Steven Traver                                                                                                                                                         |
| 567 |    130.160879 |    343.960058 | Gareth Monger                                                                                                                                                         |
| 568 |    574.492323 |     52.970153 | Birgit Lang                                                                                                                                                           |
| 569 |    419.075868 |    132.090674 | Julio Garza                                                                                                                                                           |
| 570 |    575.181573 |    784.702049 | Joedison Rocha                                                                                                                                                        |
| 571 |     84.017940 |    511.292904 | Zimices                                                                                                                                                               |
| 572 |    288.587910 |    547.330781 | Tasman Dixon                                                                                                                                                          |
| 573 |     88.328765 |    151.744187 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 574 |    983.767055 |    270.077249 | NA                                                                                                                                                                    |
| 575 |    591.141446 |    740.986161 | Steven Traver                                                                                                                                                         |
| 576 |    937.016761 |    136.923757 | NA                                                                                                                                                                    |
| 577 |    787.265300 |    266.908449 | NA                                                                                                                                                                    |
| 578 |    683.498444 |     59.807633 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 579 |    534.746695 |    221.236575 | Rebecca Groom                                                                                                                                                         |
| 580 |    858.797461 |    266.490797 | Matt Crook                                                                                                                                                            |
| 581 |    993.365737 |    194.666380 | Yan Wong                                                                                                                                                              |
| 582 |    679.797007 |    700.205163 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 583 |     30.956302 |    106.924637 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 584 |    882.087713 |    513.329797 | Michelle Site                                                                                                                                                         |
| 585 |    216.255027 |    643.872882 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 586 |    490.629583 |    397.317608 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 587 |    394.092834 |    513.285044 | NA                                                                                                                                                                    |
| 588 |    924.607426 |    342.607520 | Javier Luque                                                                                                                                                          |
| 589 |     21.094509 |    105.733601 | Margot Michaud                                                                                                                                                        |
| 590 |    825.332708 |    501.251320 | Michael Scroggie                                                                                                                                                      |
| 591 |    191.223968 |     10.221624 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 592 |    717.997878 |     12.869788 | Zimices                                                                                                                                                               |
| 593 |    446.642697 |    597.682117 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 594 |    110.751311 |    368.260227 | T. Michael Keesey                                                                                                                                                     |
| 595 |    332.834356 |    235.167655 | C. Camilo Julián-Caballero                                                                                                                                            |
| 596 |    775.499998 |    566.311979 | Michelle Site                                                                                                                                                         |
| 597 |    582.902576 |    732.800612 | NA                                                                                                                                                                    |
| 598 |    259.959056 |    508.794391 | Jagged Fang Designs                                                                                                                                                   |
| 599 |    808.306757 |    709.072676 | NA                                                                                                                                                                    |
| 600 |    144.688675 |     47.426433 | Zimices                                                                                                                                                               |
| 601 |    641.550970 |    333.235909 | Abraão Leite                                                                                                                                                          |
| 602 |    918.108431 |     25.293994 | Ferran Sayol                                                                                                                                                          |
| 603 |    968.061083 |    337.089945 | Gareth Monger                                                                                                                                                         |
| 604 |   1003.478982 |    238.682881 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 605 |    464.314606 |    640.745813 | NA                                                                                                                                                                    |
| 606 |     15.278412 |    690.820293 | Matt Crook                                                                                                                                                            |
| 607 |    514.149569 |    776.231758 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 608 |     60.892674 |    418.435379 | T. Michael Keesey                                                                                                                                                     |
| 609 |    175.018469 |    313.690527 | Iain Reid                                                                                                                                                             |
| 610 |    601.514301 |    752.521288 | Martin Kevil                                                                                                                                                          |
| 611 |    183.304284 |    797.404269 | NA                                                                                                                                                                    |
| 612 |    427.643281 |    431.627326 | Sean McCann                                                                                                                                                           |
| 613 |    702.086495 |    171.441721 | Zimices                                                                                                                                                               |
| 614 |    388.205454 |    584.948106 | Chris huh                                                                                                                                                             |
| 615 |    637.402503 |    268.104162 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 616 |    724.103664 |    711.200281 | Scott Hartman                                                                                                                                                         |
| 617 |    674.233108 |    181.670168 | Ferran Sayol                                                                                                                                                          |
| 618 |    870.910071 |    624.655138 | Matt Crook                                                                                                                                                            |
| 619 |    433.230169 |    192.565113 | Kai R. Caspar                                                                                                                                                         |
| 620 |    508.265557 |    546.686277 | NA                                                                                                                                                                    |
| 621 |    505.438963 |    689.924484 | Michelle Site                                                                                                                                                         |
| 622 |    509.556851 |    141.907691 | Mattia Menchetti                                                                                                                                                      |
| 623 |    740.947332 |    687.382161 | Matt Crook                                                                                                                                                            |
| 624 |    892.905039 |    781.295580 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 625 |    530.797517 |    774.424698 | Becky Barnes                                                                                                                                                          |
| 626 |    357.870084 |    257.407662 | Jagged Fang Designs                                                                                                                                                   |
| 627 |    632.019144 |    633.324286 | Steven Traver                                                                                                                                                         |
| 628 |    796.654374 |    706.785444 | Kamil S. Jaron                                                                                                                                                        |
| 629 |    145.403503 |    369.277625 | Elisabeth Östman                                                                                                                                                      |
| 630 |    463.404952 |    549.199688 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 631 |    615.365904 |    240.630779 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 632 |    328.140060 |    431.826605 | NA                                                                                                                                                                    |
| 633 |   1009.655600 |    728.795059 | Ferran Sayol                                                                                                                                                          |
| 634 |    551.425981 |    771.912206 | Harold N Eyster                                                                                                                                                       |
| 635 |    526.760116 |    155.041017 | C. Camilo Julián-Caballero                                                                                                                                            |
| 636 |    187.395046 |    316.645778 | Rebecca Groom                                                                                                                                                         |
| 637 |      8.217606 |    299.152595 | Zimices                                                                                                                                                               |
| 638 |    744.082773 |    150.528367 | Christoph Schomburg                                                                                                                                                   |
| 639 |     98.379314 |    614.370548 | Sarah Werning                                                                                                                                                         |
| 640 |    108.552907 |    451.998698 | Steven Traver                                                                                                                                                         |
| 641 |     37.492911 |     35.978014 | L. Shyamal                                                                                                                                                            |
| 642 |    549.023956 |     26.602053 | NA                                                                                                                                                                    |
| 643 |    754.452250 |    352.103237 | Scott Reid                                                                                                                                                            |
| 644 |    878.731921 |    454.016892 | Caleb M. Brown                                                                                                                                                        |
| 645 |   1001.860104 |    139.259546 | Zimices                                                                                                                                                               |
| 646 |    326.535546 |    400.883803 | Pedro de Siracusa                                                                                                                                                     |
| 647 |    215.361235 |     20.177960 | Christoph Schomburg                                                                                                                                                   |
| 648 |     92.307720 |    784.472969 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 649 |    122.867441 |    215.760500 | Kamil S. Jaron                                                                                                                                                        |
| 650 |    525.961878 |    216.064261 | Scott Hartman                                                                                                                                                         |
| 651 |   1007.377686 |    566.812474 | Gareth Monger                                                                                                                                                         |
| 652 |    875.857126 |    600.579375 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 653 |    730.988563 |    680.536647 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 654 |    968.906864 |    189.910650 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 655 |    392.436525 |    783.936425 | NA                                                                                                                                                                    |
| 656 |    491.662070 |    406.775992 | Matt Crook                                                                                                                                                            |
| 657 |    210.592617 |    657.024472 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 658 |    125.750076 |    437.098817 | Sarah Werning                                                                                                                                                         |
| 659 |    549.015122 |    289.572145 | NA                                                                                                                                                                    |
| 660 |    711.754298 |    208.384630 | Matt Crook                                                                                                                                                            |
| 661 |    404.490391 |     43.118841 | Melissa Broussard                                                                                                                                                     |
| 662 |    102.539708 |    310.079964 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 663 |    956.984535 |    638.416874 | Matt Crook                                                                                                                                                            |
| 664 |    199.617452 |    604.354795 | Birgit Lang                                                                                                                                                           |
| 665 |    367.628880 |    366.342281 | NA                                                                                                                                                                    |
| 666 |    113.162006 |    349.644677 | Martin Kevil                                                                                                                                                          |
| 667 |    654.458496 |    677.463346 | Josefine Bohr Brask                                                                                                                                                   |
| 668 |    375.364410 |    495.642585 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 669 |    270.307200 |    489.248631 | Caleb M. Brown                                                                                                                                                        |
| 670 |    452.644847 |    561.201197 | Manabu Bessho-Uehara                                                                                                                                                  |
| 671 |    382.031596 |    605.265055 | Margot Michaud                                                                                                                                                        |
| 672 |    987.503581 |    394.048220 | T. Michael Keesey                                                                                                                                                     |
| 673 |    215.404756 |    689.525570 | Ferran Sayol                                                                                                                                                          |
| 674 |    818.149739 |    787.592467 | Beth Reinke                                                                                                                                                           |
| 675 |    202.942773 |    135.488835 | Alexandre Vong                                                                                                                                                        |
| 676 |    585.031011 |    585.468536 | Jagged Fang Designs                                                                                                                                                   |
| 677 |    356.717694 |    246.950790 | Margot Michaud                                                                                                                                                        |
| 678 |    946.785691 |    279.597252 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 679 |    649.367492 |    638.559199 | NA                                                                                                                                                                    |
| 680 |    683.805666 |    717.698397 | Zimices                                                                                                                                                               |
| 681 |    987.679244 |    632.202672 | Gareth Monger                                                                                                                                                         |
| 682 |    744.967933 |    540.994757 | Steven Traver                                                                                                                                                         |
| 683 |    793.787073 |    715.248390 |                                                                                                                                                                       |
| 684 |     85.386176 |    445.892176 | Pete Buchholz                                                                                                                                                         |
| 685 |    978.267112 |    174.437678 | Sarah Werning                                                                                                                                                         |
| 686 |    122.842202 |    600.609249 | Emily Willoughby                                                                                                                                                      |
| 687 |    134.426979 |    512.085924 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 688 |    842.338924 |     53.607147 | Christoph Schomburg                                                                                                                                                   |
| 689 |     96.688073 |    371.152537 | Dann Pigdon                                                                                                                                                           |
| 690 |    103.834029 |    534.606437 | Michele Tobias                                                                                                                                                        |
| 691 |    450.785424 |    405.028980 | NA                                                                                                                                                                    |
| 692 |    140.038379 |     39.287716 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 693 |    519.130630 |    313.460425 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 694 |    556.379554 |    480.667025 | Jake Warner                                                                                                                                                           |
| 695 |   1015.772500 |    514.131869 | NA                                                                                                                                                                    |
| 696 |   1013.154048 |    133.401465 | Chris huh                                                                                                                                                             |
| 697 |    420.770250 |    117.044247 | NA                                                                                                                                                                    |
| 698 |    615.719571 |    363.602411 | C. Camilo Julián-Caballero                                                                                                                                            |
| 699 |     20.383017 |    214.831000 | NA                                                                                                                                                                    |
| 700 |    476.318829 |    311.376243 | Katie S. Collins                                                                                                                                                      |
| 701 |     74.864666 |    794.854483 | NA                                                                                                                                                                    |
| 702 |    357.373385 |     30.571388 | Matt Crook                                                                                                                                                            |
| 703 |    334.854690 |    605.900936 | Jimmy Bernot                                                                                                                                                          |
| 704 |    948.059236 |    411.074173 | Margot Michaud                                                                                                                                                        |
| 705 |    133.605563 |    698.191812 | Matt Crook                                                                                                                                                            |
| 706 |    300.381920 |    500.572925 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 707 |    145.665095 |    333.105080 | Zimices                                                                                                                                                               |
| 708 |     44.917095 |    614.188466 | Margot Michaud                                                                                                                                                        |
| 709 |    865.145684 |    237.271993 | Ferran Sayol                                                                                                                                                          |
| 710 |    266.954459 |    284.981779 | Qiang Ou                                                                                                                                                              |
| 711 |    826.050118 |    624.441972 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 712 |    384.810558 |    769.211999 | Ferran Sayol                                                                                                                                                          |
| 713 |    147.970744 |    792.189580 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 714 |    603.993786 |    278.677075 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 715 |    817.416404 |    737.883068 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 716 |    432.633672 |    239.523993 | Steven Traver                                                                                                                                                         |
| 717 |    479.768059 |    663.284337 | Collin Gross                                                                                                                                                          |
| 718 |    654.980498 |     26.483554 | Lukasiniho                                                                                                                                                            |
| 719 |   1005.368498 |     23.194895 | Matt Crook                                                                                                                                                            |
| 720 |    961.276194 |    145.892010 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 721 |    240.621035 |    740.415505 | Smokeybjb                                                                                                                                                             |
| 722 |    128.669614 |    445.605934 | Michelle Site                                                                                                                                                         |
| 723 |    546.465419 |    140.099830 | NA                                                                                                                                                                    |
| 724 |    245.069102 |     21.892509 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 725 |   1002.303464 |    709.517216 | Chris huh                                                                                                                                                             |
| 726 |    182.699568 |    308.331508 | Manabu Bessho-Uehara                                                                                                                                                  |
| 727 |    777.988264 |    180.138867 | L. Shyamal                                                                                                                                                            |
| 728 |    642.088023 |     14.187819 | Beth Reinke                                                                                                                                                           |
| 729 |    566.252766 |    210.789116 | Margot Michaud                                                                                                                                                        |
| 730 |    366.548725 |    608.407451 | Kamil S. Jaron                                                                                                                                                        |
| 731 |    891.079650 |     27.600115 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 732 |    195.574462 |    522.955686 | Zimices                                                                                                                                                               |
| 733 |    410.516652 |    306.232597 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 734 |    448.045677 |    422.544358 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                          |
| 735 |     18.034398 |     78.342090 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 736 |     53.779958 |    101.284875 | Scott Hartman                                                                                                                                                         |
| 737 |    265.281205 |    135.778826 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 738 |    686.905661 |    153.093234 | Lukasiniho                                                                                                                                                            |
| 739 |    427.108536 |    211.219667 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 740 |    964.436493 |    106.783421 | Michelle Site                                                                                                                                                         |
| 741 |    379.924230 |    321.497567 | Inessa Voet                                                                                                                                                           |
| 742 |    768.424973 |    586.041905 | NA                                                                                                                                                                    |
| 743 |    821.417184 |    213.110133 | xgirouxb                                                                                                                                                              |
| 744 |   1005.695101 |    715.069776 | Chris huh                                                                                                                                                             |
| 745 |    766.293682 |    495.078220 | Christoph Schomburg                                                                                                                                                   |
| 746 |    884.799818 |    494.705332 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 747 |    351.794725 |    643.204477 | Alexandre Vong                                                                                                                                                        |
| 748 |     34.713499 |    523.631778 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 749 |    681.395361 |    656.646554 | Emily Willoughby                                                                                                                                                      |
| 750 |    542.406945 |    179.673854 | B. Duygu Özpolat                                                                                                                                                      |
| 751 |    216.099503 |    676.030146 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 752 |    561.837071 |    727.771722 | Andrew A. Farke                                                                                                                                                       |
| 753 |   1008.545207 |    662.065921 | Steven Traver                                                                                                                                                         |
| 754 |    905.268957 |     11.399559 | T. Michael Keesey                                                                                                                                                     |
| 755 |    285.573301 |     12.029487 | Crystal Maier                                                                                                                                                         |
| 756 |     25.682145 |    241.514004 | FunkMonk                                                                                                                                                              |
| 757 |    829.903922 |    406.526126 | T. Michael Keesey                                                                                                                                                     |
| 758 |    828.015861 |    355.177737 | Kai R. Caspar                                                                                                                                                         |
| 759 |    789.976418 |    674.398363 | Tyler McCraney                                                                                                                                                        |
| 760 |     17.996800 |    521.839741 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 761 |    502.687655 |    523.711656 | Steven Traver                                                                                                                                                         |
| 762 |    751.369118 |    264.440588 | Rene Martin                                                                                                                                                           |
| 763 |    472.046186 |    561.327087 | Zimices                                                                                                                                                               |
| 764 |    684.097587 |     15.399268 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 765 |    754.896156 |    709.291089 | Cagri Cevrim                                                                                                                                                          |
| 766 |    871.219693 |    530.341823 | NA                                                                                                                                                                    |
| 767 |    428.706233 |     43.220028 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 768 |    786.752233 |      8.777738 | Joanna Wolfe                                                                                                                                                          |
| 769 |    587.181539 |     49.851122 | Zimices                                                                                                                                                               |
| 770 |    366.214024 |    713.454988 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 771 |    728.668226 |    447.715041 | Chris huh                                                                                                                                                             |
| 772 |    776.358196 |    270.834084 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 773 |    374.318359 |    346.995264 | Yan Wong                                                                                                                                                              |
| 774 |    581.995810 |    271.488898 | NA                                                                                                                                                                    |
| 775 |    319.136460 |    517.975711 | Chris huh                                                                                                                                                             |
| 776 |    224.274488 |    734.255373 | Scott Hartman                                                                                                                                                         |
| 777 |    693.672796 |    325.881383 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 778 |    898.567819 |    423.891228 | Mathilde Cordellier                                                                                                                                                   |
| 779 |    674.202054 |    166.739719 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 780 |     55.715342 |    180.015724 | Gareth Monger                                                                                                                                                         |
| 781 |    165.332335 |    327.831136 | Margot Michaud                                                                                                                                                        |
| 782 |   1009.635679 |    201.763632 | Michael Scroggie                                                                                                                                                      |
| 783 |    498.528923 |     14.714090 | Matt Crook                                                                                                                                                            |
| 784 |    371.690663 |    528.774202 | Scott Hartman                                                                                                                                                         |
| 785 |    300.395327 |    202.178051 | Gareth Monger                                                                                                                                                         |
| 786 |    623.392545 |    231.316041 | Ferran Sayol                                                                                                                                                          |
| 787 |    459.234043 |    352.128956 | Steven Traver                                                                                                                                                         |
| 788 |    626.970116 |    254.973527 | Scott Hartman                                                                                                                                                         |
| 789 |    186.234952 |    545.925809 | Tracy A. Heath                                                                                                                                                        |
| 790 |    843.306674 |    720.869136 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 791 |    211.478018 |    544.285333 | David Orr                                                                                                                                                             |
| 792 |    908.386727 |    761.346938 | Zimices                                                                                                                                                               |
| 793 |    587.861729 |    592.519074 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 794 |    660.588586 |    669.089848 | Shyamal                                                                                                                                                               |
| 795 |     88.662828 |    223.707481 | Anthony Caravaggi                                                                                                                                                     |
| 796 |    264.798600 |     95.834278 | Margot Michaud                                                                                                                                                        |
| 797 |    106.515660 |    197.657604 | Chris Jennings (Risiatto)                                                                                                                                             |
| 798 |   1014.541226 |    600.123808 | Jagged Fang Designs                                                                                                                                                   |
| 799 |   1010.740714 |    751.370628 | Zimices                                                                                                                                                               |
| 800 |     88.053689 |    648.510523 | T. Michael Keesey                                                                                                                                                     |
| 801 |    687.130979 |     47.188602 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 802 |    638.722968 |    587.515709 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 803 |    847.124680 |    522.009083 | Chris huh                                                                                                                                                             |
| 804 |    122.051130 |    241.230537 | C. Camilo Julián-Caballero                                                                                                                                            |
| 805 |    857.033725 |    334.332111 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 806 |     90.847708 |    236.753423 | Pete Buchholz                                                                                                                                                         |
| 807 |    849.437827 |    201.866386 | Margot Michaud                                                                                                                                                        |
| 808 |    875.686351 |     68.092283 | Margot Michaud                                                                                                                                                        |
| 809 |    209.364854 |    282.677674 | NA                                                                                                                                                                    |
| 810 |    709.615740 |    224.120723 | Jagged Fang Designs                                                                                                                                                   |
| 811 |    655.482996 |      6.178607 | Tyler McCraney                                                                                                                                                        |
| 812 |    504.247943 |    283.883717 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 813 |    201.212086 |    159.180935 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 814 |    290.830021 |    796.291917 | Zimices                                                                                                                                                               |
| 815 |    194.669768 |    403.409680 | Andrew A. Farke                                                                                                                                                       |
| 816 |    486.371122 |    297.934680 | Rebecca Groom                                                                                                                                                         |
| 817 |    662.160491 |    265.834226 | Margot Michaud                                                                                                                                                        |
| 818 |    347.683501 |     64.150578 | Oliver Griffith                                                                                                                                                       |
| 819 |    948.583925 |    788.425756 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 820 |    562.229662 |    616.834390 | Ludwik Gasiorowski                                                                                                                                                    |
| 821 |    638.462100 |    676.593996 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 822 |    585.885957 |    612.192264 | Zimices                                                                                                                                                               |
| 823 |    634.798965 |    643.817590 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 824 |    742.913029 |    158.602896 | Matt Martyniuk                                                                                                                                                        |
| 825 |    305.355390 |      8.113922 | Matt Crook                                                                                                                                                            |
| 826 |    215.308106 |    438.350804 | Michelle Site                                                                                                                                                         |
| 827 |    963.976378 |    139.343887 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 828 |    438.073169 |     13.581239 | Maija Karala                                                                                                                                                          |
| 829 |    779.101513 |    611.220612 | Scott Hartman                                                                                                                                                         |
| 830 |    711.780829 |    161.514404 | Sarah Werning                                                                                                                                                         |
| 831 |    591.033255 |     18.835481 | Christoph Schomburg                                                                                                                                                   |
| 832 |     11.219276 |    714.870076 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 833 |    174.757921 |    412.284631 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 834 |    836.805063 |    307.907968 | Matt Crook                                                                                                                                                            |
| 835 |    210.404709 |    451.525934 | Ferran Sayol                                                                                                                                                          |
| 836 |     56.708185 |     32.049182 | Robert Gay                                                                                                                                                            |
| 837 |    549.399578 |    173.614939 | Christopher Chávez                                                                                                                                                    |
| 838 |    446.395230 |    483.644827 | Kamil S. Jaron                                                                                                                                                        |
| 839 |    110.917899 |    194.066733 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 840 |    165.732069 |    681.976450 | Josep Marti Solans                                                                                                                                                    |
| 841 |    692.470172 |    351.611725 | FunkMonk                                                                                                                                                              |
| 842 |    829.808540 |    395.765918 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 843 |     12.799174 |     68.257695 | Zimices                                                                                                                                                               |
| 844 |    641.712038 |    372.708596 | Andrew A. Farke                                                                                                                                                       |
| 845 |    100.885665 |    595.270091 | Steven Traver                                                                                                                                                         |
| 846 |    476.052868 |    124.177064 | NA                                                                                                                                                                    |
| 847 |    714.783429 |    471.386016 | Margot Michaud                                                                                                                                                        |
| 848 |    908.796266 |    719.473868 | Ferran Sayol                                                                                                                                                          |
| 849 |    608.897661 |     59.922833 | Tracy A. Heath                                                                                                                                                        |
| 850 |     89.359536 |    489.762988 | Allison Pease                                                                                                                                                         |
| 851 |    943.726756 |    716.575409 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 852 |    273.532884 |    785.493630 | Tasman Dixon                                                                                                                                                          |
| 853 |    924.446328 |    150.701667 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 854 |    855.222448 |     30.363663 | Chris huh                                                                                                                                                             |
| 855 |     47.365029 |    569.996431 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 856 |    626.837095 |    749.554546 | Zimices                                                                                                                                                               |
| 857 |    533.039141 |    125.538763 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 858 |    797.998919 |    505.430860 | Tracy A. Heath                                                                                                                                                        |
| 859 |    717.047607 |    254.689610 | Darius Nau                                                                                                                                                            |
| 860 |    107.377497 |    333.107675 | Andrew A. Farke                                                                                                                                                       |
| 861 |    154.891743 |    655.920298 | Maxime Dahirel                                                                                                                                                        |
| 862 |    428.183607 |    179.379859 | Margot Michaud                                                                                                                                                        |
| 863 |    426.249654 |    276.186681 | Jaime Headden                                                                                                                                                         |
| 864 |    557.496086 |    366.751216 | Ryan Cupo                                                                                                                                                             |
| 865 |    322.186498 |    132.937143 | Cagri Cevrim                                                                                                                                                          |
| 866 |    836.366367 |    300.909750 | Chris huh                                                                                                                                                             |
| 867 |    436.264767 |     54.110395 | Scott Hartman                                                                                                                                                         |
| 868 |    119.699443 |    794.724944 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 869 |    189.610385 |    668.420093 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 870 |    147.368794 |    497.274719 | Gareth Monger                                                                                                                                                         |
| 871 |    880.863219 |    367.059488 | Margot Michaud                                                                                                                                                        |
| 872 |    963.651682 |    511.957591 | NA                                                                                                                                                                    |
| 873 |    676.058983 |     49.883389 | Trond R. Oskars                                                                                                                                                       |
| 874 |    990.454268 |    577.189035 | Gareth Monger                                                                                                                                                         |
| 875 |    252.532418 |    160.292676 | Matt Crook                                                                                                                                                            |
| 876 |    227.070807 |     11.709957 | Geoff Shaw                                                                                                                                                            |
| 877 |     11.195701 |    144.629451 | Catherine Yasuda                                                                                                                                                      |
| 878 |    518.568180 |     17.423599 | Shyamal                                                                                                                                                               |
| 879 |    611.705050 |    736.906921 | Oscar Sanisidro                                                                                                                                                       |
| 880 |   1012.957481 |     61.414445 | Matt Crook                                                                                                                                                            |
| 881 |     22.164664 |    189.329891 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 882 |    607.547640 |    339.473531 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 883 |    402.054687 |     27.122476 | \[unknown\]                                                                                                                                                           |
| 884 |    208.196309 |    513.955619 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 885 |    994.156708 |     74.365950 | Gareth Monger                                                                                                                                                         |
| 886 |    480.868387 |    647.123954 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 887 |    295.410987 |    403.738739 | Mathilde Cordellier                                                                                                                                                   |
| 888 |    171.818770 |    469.917500 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 889 |     41.282272 |      7.682581 | T. Michael Keesey                                                                                                                                                     |
| 890 |    367.312228 |    114.051129 | Matt Crook                                                                                                                                                            |
| 891 |    369.197422 |     29.502116 | T. Michael Keesey                                                                                                                                                     |
| 892 |    273.371891 |    142.764106 | Sarah Werning                                                                                                                                                         |
| 893 |    777.927530 |    256.284121 | Julio Garza                                                                                                                                                           |
| 894 |    502.175485 |    558.490451 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 895 |    906.424031 |    553.855121 | Margot Michaud                                                                                                                                                        |
| 896 |    330.225377 |    220.862136 | Zimices                                                                                                                                                               |
| 897 |    655.608799 |     83.820442 | Pedro de Siracusa                                                                                                                                                     |
| 898 |    599.399092 |    138.221227 | NA                                                                                                                                                                    |
| 899 |    777.889507 |    121.635670 | Peileppe                                                                                                                                                              |
| 900 |     29.888532 |    204.256428 | Michael Scroggie                                                                                                                                                      |
| 901 |    211.334642 |    264.116404 | Julia B McHugh                                                                                                                                                        |
| 902 |    728.149512 |    519.599633 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 903 |    580.028966 |    291.493225 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 904 |    358.041423 |    655.267553 | Anthony Caravaggi                                                                                                                                                     |
| 905 |    668.450583 |     16.077280 | Margot Michaud                                                                                                                                                        |
| 906 |    900.988762 |    312.070844 | Scott Hartman                                                                                                                                                         |
| 907 |    592.198961 |    380.637938 | Tracy A. Heath                                                                                                                                                        |
| 908 |    877.896516 |    186.659174 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 909 |    855.973427 |    293.318851 | NA                                                                                                                                                                    |
| 910 |    427.415405 |    466.450403 | Gareth Monger                                                                                                                                                         |
| 911 |     10.839875 |     34.891246 | Taro Maeda                                                                                                                                                            |
| 912 |    739.380221 |    706.814438 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 913 |    859.247501 |    595.046274 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 914 |    532.599242 |    560.561713 | Stuart Humphries                                                                                                                                                      |
| 915 |     25.527076 |     83.850197 | Chris huh                                                                                                                                                             |
| 916 |    670.701242 |    247.546947 | Steven Traver                                                                                                                                                         |
| 917 |    103.601658 |    752.988033 | Zimices                                                                                                                                                               |
| 918 |    252.809680 |    442.530397 | Steven Traver                                                                                                                                                         |
| 919 |     67.240413 |    740.387962 | Zimices                                                                                                                                                               |

    #> Your tweet has been posted!
